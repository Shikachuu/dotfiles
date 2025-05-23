return {
  { "github/copilot.vim" },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    opts = {
      model = "claude-3.7-sonnet",
      prompts = {
        Commit = "Write commit message for the change with Conventional Commits convention. Keep the title under 50 characters and wrap message at 72 characters. Format as a gitcommit code block.",
        Review = "Please review the following code and provide suggestions for improvement.",
        Tests = "Please explain how the selected code works, then generate unit tests for it, for all possible cases.",
        GoTests = "Please generate Go unit tests for the following code. Use testify for assertions. Use table-driven tests. Every case should be run in parallel. Please generate a case for every possible input.",
        Refactor = "Please refactor the following code to improve its clarity and maintainability.",
        FixCode = "Please fix the following code to make it work as intended.",
        Documentation = "Please provide documentation for the following code. Use the given language's documentation style. (e.g. JSDoc, godoc, etc.)",
        OpenAPIDocs = "Please provide documentation for the following API endpoint(s) using OpenAPI.",
        Spelling = "Please correct any grammar and spelling errors in the following text.",
      },
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
