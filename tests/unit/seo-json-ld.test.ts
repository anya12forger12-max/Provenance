import { expect, test } from "vitest";
import { jsonLd } from "@/lib/seo/jsonLd";

test("escapes markup terminators from upstream strings", () => {
  const html = jsonLd({
    name: '</script><img src=x onerror=alert(1)>',
    nested: ["A&B", "line\u2028break"],
  });

  expect(html).not.toContain("</script>");
  expect(html).not.toContain("<img");
  expect(html).not.toContain("&");
  expect(html).toContain("\\u003c/script\\u003e");
  expect(html).toContain("A\\u0026B");
  expect(html).toContain("line\\u2028break");
  // Escaping must not change the value a JSON-LD consumer reads back.
  expect(JSON.parse(html)).toEqual({
    name: '</script><img src=x onerror=alert(1)>',
    nested: ["A&B", "line\u2028break"],
  });
});

test("leaves ordinary breadcrumb data unchanged apart from JSON syntax", () => {
  expect(jsonLd({ "@context": "https://schema.org", position: 1 })).toBe(
    '{"@context":"https://schema.org","position":1}',
  );
});
