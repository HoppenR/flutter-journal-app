local journal_root = os.getenv("JOURNAL_HOME")

return {
    name = 'dartls',
    cmd = {
        'dart',
        'language-server',
        '--protocol=lsp',
        "--client-id=nvim.lsp",
        "--client-version=" .. vim.version().major .. "." .. vim.version().minor,
    },
    filetypes = { 'dart' },
    root_dir = journal_root,
    init_options = {
        closingLabels = true,
        flutterOutline = true,
        onlyAnalyzeProjectsWithOpenFiles = true,
        suggestFromUnimportedLibraries = true,
    },
    settings = {
        dart = {
            updateImportsOnRename = true,
            completeFunctionCalls = true,
            showTodos = true,
        },
    },
    capabilities = { offsetEncoding = { "utf-16" } },
}
