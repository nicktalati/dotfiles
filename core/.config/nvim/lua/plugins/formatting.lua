return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>cf",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            desc = "Format buffer",
        },
    },
    opts = {
        formatters_by_ft = {
            markdown = { "mdformat" },
        },
        formatters = {
            mdformat = {
                prepend_args = { "--wrap", "80" },
            }
        },
        format_on_save = {
            timeout_ms = 3000,
            lsp_fallback = true,
        },
    },
}
