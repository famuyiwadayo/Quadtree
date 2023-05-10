const std = @import("std");
const print = std.debug.print;
const quadtree = @import("quadtree.zig");
const Point = quadtree.Point;
const QuadTree = quadtree.QuadTree;
const Rectangle = quadtree.Rectangle;

pub fn main() !void {
    const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer _ = gpa.deinit();

    const point = Point(void).init(100, 120, null);
    const boundary = Rectangle.init(point, 600, 600);
    var tree = try QuadTree.init(allocator, boundary);
    defer tree.deinit();

    // _ = try tree.insert(Point(void).init(250, 300, null));
    // _ = try tree.insert(Point(void).init(250, 300, null));

    for (0..1000) |index| {
        // var new_point = Point(void).init(250, 300, null);
        _ = try tree.insert(Point(void).init(@intToFloat(f32, index + 1), 300, null));
    }

    tree.printTree();

    // defer print("{}", .{tree});

    // print("Northwest {d}\nNortheast {d}\nSouthwest {d}\nSoutheast {d}\n", .{ tree.northwest.points.items.len, tree.northeast.points.items.len, tree.southwest.points.items.len, tree.southeast.points.items.len });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
