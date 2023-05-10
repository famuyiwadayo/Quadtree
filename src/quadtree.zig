const std = @import("std");
const fmt = std.fmt;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const IntType = f32;
const PointType = Point(void);

pub fn Point(comptime T: type) type {
    return struct {
        x: IntType,
        y: IntType,
        user_data: ?T,

        const Self = @This();

        pub fn init(x: IntType, y: IntType, data: ?T) Point(T) {
            return .{ .x = x, .y = y, .user_data = data };
        }

        pub fn format(self: Self, comptime layout: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
            _ = options;
            _ = layout;

            // try fmt.format(writer, "⎾ Point x = {d}, y = {d}\n", .{ self.x, self.y });
            // if (self.user_data) |user_data| try fmt.format(writer, "⎿ Point data {any}\n", .{user_data});
            // if (self.user_data == null) try fmt.format(writer, "⎿ null point data\n", .{});

            try fmt.format(writer, "Point ⇥ x = {d}, y = {d} ✤ Data ⇥ {any}", .{ self.x, self.y, self.user_data });
            // if (self.user_data) |user_data| try fmt.format(writer, "⎿ Point data {any}\n", .{user_data});
            // if (self.user_data == null) try fmt.format(writer, "⎿ null point data\n", .{});
        }
    };
}

pub const Rectangle = struct {
    center: PointType,
    width: IntType,
    height: IntType,

    // Regions/Segments values of the rectangle
    west: IntType,
    east: IntType,
    north: IntType,
    south: IntType,

    divided: bool = false,

    const Self = @This();

    pub fn init(center: PointType, width: IntType, height: IntType) Rectangle {
        var self: Rectangle = undefined;

        self.width = width;
        self.height = height;
        self.center = center;

        self.west = center.x - width;
        self.east = center.x + width;
        self.north = center.y - height;
        self.south = center.y + height;

        return self;
    }

    pub fn contains(self: Self, point: PointType) bool {
        return self.west <= point.x and point.x < self.east and self.north <= point.y and point.y < self.south;
    }

    pub fn setDivided(self: *Self, value: bool) void {
        self.divided = value;
    }

    pub fn format(self: Self, comptime layout: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = layout;

        const boundary_indent = ind: {
            if (self.divided) break :ind "";
            // break :ind spaces(13);
            break :ind " " ** 5 ++ "|" ++ " " ** 7;
        };

        try fmt.format(writer, "{s}├⎯⎯⎯ Center ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.center });
        try fmt.format(writer, "{s}├⎯⎯⎯ Width  ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.width });
        try fmt.format(writer, "{s}├⎯⎯⎯ Height ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.height });
        try fmt.format(writer, "{s}├⎯⎯⎯ West   ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.west });
        try fmt.format(writer, "{s}├⎯⎯⎯ East   ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.east });
        try fmt.format(writer, "{s}├⎯⎯⎯ North  ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.north });
        try fmt.format(writer, "{s}├⎯⎯⎯ South  ⎯▶︎  {}\n  ⏐\t  ", .{ boundary_indent, self.south });
        // if (self.user_data) |user_data| try fmt.format(writer, "⎿ Point data {any}\n", .{user_data});
        // if (self.user_data == null) try fmt.format(writer, "⎿ null point data\n", .{});
    }
};

pub const QuadTree = struct {
    boundary: Rectangle,
    capacity: u16,

    northwest: ?*QuadTree = undefined,
    northeast: ?*QuadTree = undefined,
    southwest: ?*QuadTree = undefined,
    southeast: ?*QuadTree = undefined,

    divided: bool = false,
    points: std.ArrayList(PointType) = undefined,

    allocator: Allocator = undefined,

    const Self = @This();

    pub fn init(allocator: Allocator, boundary: Rectangle) !*QuadTree {
        // var self: QuadTree = undefined;
        // self.capacity = 4;
        // self.allocator = allocator;
        // self.boundary = boundary;

        // self.points = std.ArrayList(PointType).init(allocator);
        var self = try createTree(allocator, boundary);
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.points.deinit();

        // if (self.northwest) |nw| nw.deinit();
        // if (self.northeast) |ne| ne.deinit();
        // if (self.southwest) |sw| sw.deinit();
        // if (self.southeast) |se| se.deinit();

        self.allocator.destroy(self);
    }

    pub fn subdivide(self: *Self) !void {
        // print("Will subdivide\n", .{});
        // b = boundary, c = center
        const bcx = self.boundary.center.x;
        const bcy = self.boundary.center.y;
        const new_width = @divExact(self.boundary.width, 2);
        const new_height = @divExact(self.boundary.height, 2);
        // print("Subdivision Variables are set\n", .{});

        // calculate the boundaries for each regions/segments of the original quadtree boundary.
        const northwest = Rectangle.init(PointType.init(bcx - new_width, bcy - new_height, null), new_width, new_height);
        const northeast = Rectangle.init(PointType.init(bcx + new_width, bcy - new_height, null), new_width, new_height);
        const southwest = Rectangle.init(PointType.init(bcx - new_width, bcy + new_height, null), new_width, new_height);
        const southeast = Rectangle.init(PointType.init(bcx + new_width, bcy + new_height, null), new_width, new_height);

        // print("North west boundaries are created \n{}\n", .{northwest});

        self.northwest = try createTree(self.allocator, northwest);
        self.northeast = try createTree(self.allocator, northeast);
        self.southwest = try createTree(self.allocator, southwest);
        self.southeast = try createTree(self.allocator, southeast);

        // print("Northwest QuadTree {any}\n", .{self.northwest.points.items});

        self.divided = true;
        self.boundary.setDivided(true);
    }

    pub fn insert(self: *Self, point: PointType) !bool {
        if (!self.boundary.contains(point)) return false;

        if (self.points.items.len < self.capacity) {
            try self.points.append(point);
            return true;
        }

        if (!self.divided) try self.subdivide();

        if (try self.northwest.?.insert(point)) {
            return true;
        } else if (try self.northeast.?.insert(point)) {
            return true;
        } else if (try self.southwest.?.insert(point)) {
            return true;
        } else if (try self.southeast.?.insert(point)) {
            return true;
        }

        // // if all goes well this line should be unreachable.
        return false;
    }

    pub fn setBoundary(self: *Self, boundary: Rectangle) QuadTree {
        self.boundary = boundary;
    }

    pub fn setCapacity(self: *Self, capacity: u16) QuadTree {
        self.capacity = capacity;
    }

    fn createTree(allocator: Allocator, boundary: Rectangle) !*QuadTree {
        var tree = try allocator.create(QuadTree);
        tree.boundary = boundary;
        tree.capacity = 4;
        tree.divided = false;
        tree.allocator = allocator;
        tree.points = std.ArrayList(PointType).init(allocator);

        return tree;
    }

    pub fn format(self: Self, comptime layout: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = layout;
        // if (self.divided) try fmt.format(writer, "        ", .{});

        const is_divided = self.boundary.divided;

        const quad_indent = ind: {
            if (is_divided) break :ind spaces(2);
            // break :ind "" ++ spaces(15);
            break :ind "  ⏐" ++ " " ** 12;
        };

        // const boundary_indent = ind: {
        //     if (is_divided) break :ind spaces(7);
        //     break :ind spaces(15 + 5);
        // };

        const after_boundary = ind: {
            if (is_divided) break :ind "";
            break :ind " " ** 5 ++ "⏐";
        };
        const after_capacity = ind: {
            if (is_divided) break :ind "";
            break :ind " " ** 12 ++ "⏐";
        };

        try fmt.format(writer, "QuadTree\n{s}├⎯⎯⎯ Boundary\n  ⏐       {}{s}", .{ quad_indent, self.boundary, after_boundary });
        try fmt.format(writer, "        \n{s}├⎯⎯⎯ Capacity   ⎯▶︎ {}\n  ⏐{s}", .{ quad_indent, self.capacity, after_capacity });
        try fmt.format(writer, "        \n{s}├⎯⎯⎯ Divided?   ⎯▶︎ {}\n  ⏐", .{ quad_indent, self.divided });
        if (self.points.items.len > 0) try fmt.format(writer, "        \n  ├⎯⎯⎯ Points     ⎯▶︎ {}\n  ⏐\t   ", .{self.points.items.len});
        for (self.points.items) |point| {
            try fmt.format(writer, "├⎯⎯⎯⎯⎯⎯ {}\n  ⏐\t   ", .{point});
        }

        // if (self.northwest != null) try fmt.format(writer, "        \n  ├⎯⎯⎯ Northwest↩︎\n{s}⏐\t   {}\n  ⏐\t   ", .{ spaces(2), self.northwest.? });

        // if (self.user_data) |user_data| try fmt.format(writer, "⎿ Point data {any}\n", .{user_data});
        // if (self.user_data == null) try fmt.format(writer, "⎿ null point data\n", .{});
    }

    pub fn printTree(self: Self) void {
        print("{}", .{self});

        self.northwest.?.printTree();
        // self.northeast.?.printTree();
        // self.southwest.?.printTree();
        // self.southeast.?.printTree();
    }
};

pub fn spaces(comptime size: usize) []const u8 {
    var _spaces = " " ** size;
    // return _spaces[0..];
    return _spaces;
}
