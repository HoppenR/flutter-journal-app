local journal_root = os.getenv("JOURNAL_HOME")
local dart_bin = os.getenv("NIX_DART_BIN")

if not (journal_root and dart_bin) then return end

return {
    name = 'dartls',
    cmd = {
        dart_bin,
        'language-server',
        '--protocol=lsp',
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
