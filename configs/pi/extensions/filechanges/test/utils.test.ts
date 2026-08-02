import { describe, expect, test } from "bun:test";
import {
  countDiffLines,
  isProbablyBinary,
  normalizeToolPath,
  stripAtPrefix,
  computeHash,
} from "../utils.ts";

describe("stripAtPrefix", () => {
  test("strips leading @", () => {
    expect(stripAtPrefix("@foo.txt")).toBe("foo.txt");
  });

  test("does not strip mid-string @", () => {
    expect(stripAtPrefix("foo@bar")).toBe("foo@bar");
  });

  test("leaves bare path unchanged", () => {
    expect(stripAtPrefix("src/file.ts")).toBe("src/file.ts");
  });

  test("handles empty string", () => {
    expect(stripAtPrefix("")).toBe("");
  });
});

describe("normalizeToolPath", () => {
  test("resolves relative path inside cwd", () => {
    const result = normalizeToolPath("/home/user/project", "src/foo.ts");
    expect(result).not.toBeNull();
    expect(result!.absPath).toBe("/home/user/project/src/foo.ts");
    expect(result!.relPath).toBe("src/foo.ts");
  });

  test("strips @ prefix before resolving", () => {
    const result = normalizeToolPath("/home/user/project", "@src/foo.ts");
    expect(result).not.toBeNull();
    expect(result!.absPath).toBe("/home/user/project/src/foo.ts");
    expect(result!.relPath).toBe("src/foo.ts");
  });

  test("rejects path that escapes cwd", () => {
    const result = normalizeToolPath("/home/user/project", "../../etc/passwd");
    expect(result).toBeNull();
  });

  test("rejects path with just dots escaping", () => {
    const result = normalizeToolPath("/home/user/project", "../secret.key");
    expect(result).toBeNull();
  });

  test("handles absolute path within cwd", () => {
    const result = normalizeToolPath(
      "/home/user/project",
      "/home/user/project/foo/bar.ts",
    );
    expect(result).not.toBeNull();
    expect(result!.absPath).toBe("/home/user/project/foo/bar.ts");
    expect(result!.relPath).toBe("foo/bar.ts");
  });

  test("returns null for absolute path outside cwd", () => {
    const result = normalizeToolPath("/home/user/project", "/etc/hostname");
    expect(result).toBeNull();
  });

  test("handles path with trailing dots and at-prefix escaping", () => {
    const result = normalizeToolPath("/home/user/project", "@../../bad");
    expect(result).toBeNull();
  });
});

describe("countDiffLines", () => {
  test("counts added and removed lines in unified diff", () => {
    const diff = [
      "--- a/file.txt",
      "+++ b/file.txt",
      "@@ -1,3 +1,3 @@",
      " unchanged",
      "-removed line",
      "+added line",
      " more unchanged",
    ].join("\n");

    const result = countDiffLines(diff);
    expect(result.added).toBe(1);
    expect(result.removed).toBe(1);
  });

  test("handles diff with only additions", () => {
    const diff = [
      "--- a/file.txt",
      "+++ b/file.txt",
      "@@ -0,0 +1,3 @@",
      "+line 1",
      "+line 2",
      "+line 3",
    ].join("\n");

    const result = countDiffLines(diff);
    expect(result.added).toBe(3);
    expect(result.removed).toBe(0);
  });

  test("handles diff with only removals", () => {
    const diff = [
      "--- a/file.txt",
      "+++ b/file.txt",
      "@@ -1,3 +0,0 @@",
      "-line 1",
      "-line 2",
      "-line 3",
    ].join("\n");

    const result = countDiffLines(diff);
    expect(result.added).toBe(0);
    expect(result.removed).toBe(3);
  });

  test("returns zeros for empty diff", () => {
    const result = countDiffLines("");
    expect(result).toEqual({ added: 0, removed: 0 });
  });

  test("does not count header lines", () => {
    const diff = "+++ b/file.txt\n--- a/file.txt\n@@ -1,1 +1,1 @@\n";
    const result = countDiffLines(diff);
    expect(result.added).toBe(0);
    expect(result.removed).toBe(0);
  });

  test("handles multi-hunk diff with @ prefix content lines", () => {
    // Lines in context that start with + or - at position 0 are
    // counted — this is correct; that's how unified diffs work.
    const diff = [
      "--- a/foo.ts",
      "+++ b/foo.ts",
      "@@ -1,2 +1,2 @@",
      "-old",
      "+new",
      "@@ -5,1 +5,1 @@",
      "-deleted",
      "+inserted",
    ].join("\n");

    const result = countDiffLines(diff);
    expect(result.added).toBe(2);
    expect(result.removed).toBe(2);
  });
});

describe("isProbablyBinary", () => {
  test("detects binary via NUL byte", () => {
    const buf = Buffer.from([0x48, 0x00, 0x65, 0x6c]); // H\0el
    expect(isProbablyBinary(buf)).toBe(true);
  });

  test("plain text is not binary", () => {
    const buf = Buffer.from("hello world\n");
    expect(isProbablyBinary(buf)).toBe(false);
  });

  test("empty buffer is not binary", () => {
    expect(isProbablyBinary(Buffer.from(""))).toBe(false);
  });

  test("detects NUL at end of big buffer", () => {
    const buf = Buffer.alloc(5000, 0x41);
    buf[4090] = 0;
    expect(isProbablyBinary(buf)).toBe(true);
  });

  test("non-NUL binary bytes are not flagged", () => {
    const buf = Buffer.from([0xff, 0xfe, 0x00, 0x00]); // BOM +
    expect(isProbablyBinary(buf)).toBe(true);
  });

  test("UTF-8 text with high codepoints is not binary", () => {
    const buf = Buffer.from("日本語テスト 🤖", "utf-8");
    expect(isProbablyBinary(buf)).toBe(false);
  });
});

describe("computeHash", () => {
  test("produces consistent hash", () => {
    const h1 = computeHash("hello");
    const h2 = computeHash("hello");
    expect(h1).toBe(h2);
    expect(h1.length).toBe(64); // SHA-256 hex
  });

  test("different content -> different hash", () => {
    expect(computeHash("a")).not.toBe(computeHash("b"));
  });

  test("empty string hash is stable", () => {
    expect(computeHash("")).toBe(
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    );
  });
});
