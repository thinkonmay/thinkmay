// Command generate builds platform icon assets from images/logo.png.
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image"
	"image/png"
	"os"
	"path/filepath"

	"golang.org/x/image/draw"
)

var (
	icoSizes   = []int{16, 24, 32, 48, 64, 128, 256}
	linuxSizes = []int{48, 128, 256, 512}
	iconset    = []struct {
		name string
		size int
	}{
		{"icon_16x16.png", 16},
		{"icon_16x16@2x.png", 32},
		{"icon_32x32.png", 32},
		{"icon_32x32@2x.png", 64},
		{"icon_128x128.png", 128},
		{"icon_128x128@2x.png", 256},
		{"icon_256x256.png", 256},
		{"icon_256x256@2x.png", 512},
		{"icon_512x512.png", 512},
		{"icon_512x512@2x.png", 1024},
	}
)

func main() {
	root, err := findRepoRoot()
	if err != nil {
		fatal(err)
	}

	srcPath := filepath.Join(root, "images", "logo.png")
	src, err := loadPNG(srcPath)
	if err != nil {
		fatal(fmt.Errorf("load %s: %w", srcPath, err))
	}

	master := resizeSquare(src, 1024)
	if err := writePNG(filepath.Join(root, "images", "logo.png"), master); err != nil {
		fatal(err)
	}

	if err := writeICO(filepath.Join(root, "images", "logo.ico"), master, icoSizes); err != nil {
		fatal(err)
	}

	embed := resizeSquare(master, 512)
	if err := writePNG(filepath.Join(root, "worker", "proxy", "client", "app", "logo.png"), embed); err != nil {
		fatal(err)
	}

	linuxRoot := filepath.Join(root, "packaging", "client", "linux", "icons", "hicolor")
	for _, size := range linuxSizes {
		dir := filepath.Join(linuxRoot, fmt.Sprintf("%dx%d", size, size), "apps")
		if err := os.MkdirAll(dir, 0o755); err != nil {
			fatal(err)
		}
		if err := writePNG(filepath.Join(dir, "thinkmay-client.png"), resizeSquare(master, size)); err != nil {
			fatal(err)
		}
	}
	legacy := filepath.Join(root, "packaging", "client", "linux", "thinkmay-client.png")
	if err := writePNG(legacy, resizeSquare(master, 256)); err != nil {
		fatal(err)
	}

	iconsetDir := filepath.Join(root, "packaging", "client", "macos", "AppIcon.iconset")
	if err := os.RemoveAll(iconsetDir); err != nil {
		fatal(err)
	}
	if err := os.MkdirAll(iconsetDir, 0o755); err != nil {
		fatal(err)
	}
	for _, item := range iconset {
		if err := writePNG(filepath.Join(iconsetDir, item.name), resizeSquare(master, item.size)); err != nil {
			fatal(err)
		}
	}

	fmt.Println("generated icons from", srcPath)
	fmt.Println("  images/logo.png (1024)")
	fmt.Println("  images/logo.ico")
	fmt.Println("  worker/proxy/client/app/logo.png (512)")
	fmt.Println("  packaging/client/linux/icons/hicolor/{48,128,256,512}x*/apps/")
	fmt.Println("  packaging/client/macos/AppIcon.iconset/")
	fmt.Println("run iconutil on macOS to refresh AppIcon.icns")
}

func findRepoRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "images", "logo.png")); err == nil {
			if _, err := os.Stat(filepath.Join(dir, "packaging", "client")); err == nil {
				return dir, nil
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("repo root not found")
		}
		dir = parent
	}
}

func loadPNG(path string) (image.Image, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return png.Decode(f)
}

func resizeSquare(src image.Image, size int) *image.RGBA {
	dst := image.NewRGBA(image.Rect(0, 0, size, size))
	draw.CatmullRom.Scale(dst, dst.Bounds(), src, src.Bounds(), draw.Over, nil)
	return dst
}

func writePNG(path string, img image.Image) error {
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		return err
	}
	return os.WriteFile(path, buf.Bytes(), 0o644)
}

func writeICO(path string, master *image.RGBA, sizes []int) error {
	type entry struct {
		size int
		png  []byte
	}
	entries := make([]entry, 0, len(sizes))
	for _, size := range sizes {
		img := master
		if size != master.Bounds().Dx() {
			img = resizeSquare(master, size)
		}
		var buf bytes.Buffer
		if err := png.Encode(&buf, img); err != nil {
			return err
		}
		entries = append(entries, entry{size: size, png: buf.Bytes()})
	}

	var out bytes.Buffer
	if err := binary.Write(&out, binary.LittleEndian, uint16(0)); err != nil {
		return err
	}
	if err := binary.Write(&out, binary.LittleEndian, uint16(1)); err != nil {
		return err
	}
	if err := binary.Write(&out, binary.LittleEndian, uint16(len(entries))); err != nil {
		return err
	}

	offset := 6 + len(entries)*16
	for _, e := range entries {
		w, h := byte(e.size), byte(e.size)
		if e.size >= 256 {
			w, h = 0, 0
		}
		out.WriteByte(w)
		out.WriteByte(h)
		out.WriteByte(0)
		out.WriteByte(0)
		_ = binary.Write(&out, binary.LittleEndian, uint16(1))
		_ = binary.Write(&out, binary.LittleEndian, uint16(32))
		_ = binary.Write(&out, binary.LittleEndian, uint32(len(e.png)))
		_ = binary.Write(&out, binary.LittleEndian, uint32(offset))
		offset += len(e.png)
	}
	for _, e := range entries {
		out.Write(e.png)
	}
	return os.WriteFile(path, out.Bytes(), 0o644)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
