#!/usr/bin/env swift
import AppKit

/// Flood from edges on pixels near the average corner color (same idea as `MenuBarIcon.floodEraseOuterBackgroundMatchingCorners`).
/// Use for flat RGB menu bar PNGs so README + menu bar show transparency.
func floodEraseOuterBackgroundMatchingCorners(rep: NSBitmapImageRep, width: Int, height: Int) {
    guard width > 1, height > 1, let data = rep.bitmapData else { return }
    let bpr = rep.bytesPerRow
    let thresh = 14

    func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
        let o = y * bpr + x * 4
        return (Int(data[o]), Int(data[o + 1]), Int(data[o + 2]))
    }

    let corners = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    var cr = 0, cg = 0, cb = 0
    for (x, y) in corners {
        let p = rgb(x, y)
        cr += p.0
        cg += p.1
        cb += p.2
    }
    cr /= 4
    cg /= 4
    cb /= 4

    func matchesBackground(_ x: Int, _ y: Int) -> Bool {
        let p = rgb(x, y)
        return abs(p.0 - cr) <= thresh && abs(p.1 - cg) <= thresh && abs(p.2 - cb) <= thresh
    }

    var visited = [Bool](repeating: false, count: width * height)
    var queue: [(Int, Int)] = []
    var head = 0
    func idx(_ x: Int, _ y: Int) -> Int { y * width + x }

    for x in 0..<width {
        for y in [0, height - 1] {
            let i = idx(x, y)
            if !visited[i], matchesBackground(x, y) {
                visited[i] = true
                queue.append((x, y))
            }
        }
    }
    for y in 0..<height {
        for x in [0, width - 1] {
            let i = idx(x, y)
            if !visited[i], matchesBackground(x, y) {
                visited[i] = true
                queue.append((x, y))
            }
        }
    }

    let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    while head < queue.count {
        let (x, y) = queue[head]
        head += 1
        let o = y * bpr + x * 4
        data[o + 3] = 0
        for (dx, dy) in dirs {
            let nx = x + dx
            let ny = y + dy
            guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
            let ni = idx(nx, ny)
            if visited[ni] { continue }
            if matchesBackground(nx, ny) {
                visited[ni] = true
                queue.append((nx, ny))
            }
        }
    }
}

func rasterizeToRGBA(_ image: NSImage) -> NSBitmapImageRep? {
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let w = cg.width
    let h = cg.height
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: w,
        pixelsHigh: h,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .none
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: w, height: h).fill()
    let rect = NSRect(x: 0, y: 0, width: w, height: h)
    image.draw(in: rect, from: rect, operation: .copy, fraction: 1, respectFlipped: false, hints: [.interpolation: NSImageInterpolation.none])
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func processFile(_ path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let img = NSImage(contentsOf: url) else {
        fputs("skip (load failed): \(path)\n", stderr)
        return false
    }
    guard let rep = rasterizeToRGBA(img) else {
        fputs("skip (raster): \(path)\n", stderr)
        return false
    }
    let w = rep.pixelsWide
    let h = rep.pixelsHigh
    floodEraseOuterBackgroundMatchingCorners(rep: rep, width: w, height: h)
    guard let data = rep.representation(using: .png, properties: [.compressionFactor: 1]) else {
        fputs("skip (encode): \(path)\n", stderr)
        return false
    }
    do {
        try data.write(to: url)
        print("ok: \(path)")
        return true
    } catch {
        fputs("skip (write \(error)): \(path)\n", stderr)
        return false
    }
}

let args = Array(CommandLine.arguments.dropFirst())
if args.isEmpty {
    fputs("Usage: StripMenuBarPNGBackground.swift <file.png> ...\n", stderr)
    exit(1)
}
var ok = 0
for p in args {
    if processFile(p) { ok += 1 }
}
exit(ok == args.count ? 0 : 2)
