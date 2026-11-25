/**
 * Serialize a value for `<script type="application/ld+json">`.
 *
 * JSON.stringify on its own is not safe in a script element: an upstream string
 * containing `</script>` closes the element and everything after it is parsed as
 * HTML. Camera names and regions come from third-party feeds, so escape the
 * characters that can terminate a script or open an entity. The emitted JSON is
 * still valid — `\u003c` is simply another spelling of `<` inside a JSON string.
 */
export function jsonLd(value: unknown): string {
  return JSON.stringify(value)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026")
    .replace(/\u2028/g, "\\u2028")
    .replace(/\u2029/g, "\\u2029");
}
