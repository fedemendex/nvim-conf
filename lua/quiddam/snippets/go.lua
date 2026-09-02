local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    -- interface
    s("inter", {
        t("type "),
        i(1, "Name"),
        t({ " interface {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- struct
    s("stru", {
        t("type "),
        i(1, "Name"),
        t({ " struct {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- Basic test
    s("test", {
        t("func Test"),
        i(1, "Name"),
        t({ "(t *testing.T) {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- Function
    s("func", {
        t("func "),
        i(1, "name"),
        t("("),
        i(2),
        t(") "),
        i(3, "error"),
        t({ " {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- Method
    s("meth", {
        t("func ("),
        i(1, "s"),
        t(" *"),
        i(2, "Service"),
        t(") "),
        i(3, "name"),
        t("("),
        i(4),
        t(") "),
        i(5, "error"),
        t({ " {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- Range loop
    s("forr", {
        t("for "),
        i(1, "_, value"),
        t(" := range "),
        i(2, "values"),
        t({ " {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
    -- if err != nil {}
    s("iferr", {
        t({ "if err != nil {", "\t" }),
        i(0),
        t({ "", "}" }),
    }),
}
