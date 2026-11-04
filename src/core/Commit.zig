const Commit = @This();

commit_id: []const u8,
parents: []const []const u8,
description: []const u8,
author: Signature,
committer: Signature,

const Signature = struct {
    name: []const u8,
    email: []const u8,
    timestamp: []const u8,
};
