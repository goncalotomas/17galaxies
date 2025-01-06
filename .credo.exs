%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "test/"],
        excluded: []
      },
      plugins: [],
      requires: [],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: %{
        disabled: [
          {Credo.Check.Design.TagTODO, []},
          # Styler Rewrites
          #
          # The following rules are automatically rewritten by Styler and so disabled here to save time
          # Some of the rules have `priority: :high`, meaning Credo runs them unless we explicitly disable them
          # (removing them from this file wouldn't be enough, the `false` is required)
          #
          {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
          {Credo.Check.Consistency.ParameterPatternMatching, false},
          {Credo.Check.Design.AliasUsage, false},
          {Credo.Check.Readability.AliasOrder, false},
          {Credo.Check.Readability.BlockPipe, false},
          {Credo.Check.Readability.LargeNumbers, false},
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.MultiAlias, false},
          {Credo.Check.Readability.OneArityFunctionInPipe, false},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, false},
          {Credo.Check.Readability.PreferImplicitTry, false},
          {Credo.Check.Readability.SinglePipe, false},
          {Credo.Check.Readability.StrictModuleLayout, false},
          {Credo.Check.Readability.StringSigils, false},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
          {Credo.Check.Readability.WithSingleClause, false},
          {Credo.Check.Refactor.CaseTrivialMatches, false},
          {Credo.Check.Refactor.CondStatements, false},
          {Credo.Check.Refactor.FilterCount, false},
          {Credo.Check.Refactor.MapInto, false},
          {Credo.Check.Refactor.MapJoin, false},
          {Credo.Check.Refactor.NegatedConditionsInUnless, false},
          {Credo.Check.Refactor.NegatedConditionsWithElse, false},
          {Credo.Check.Refactor.PipeChainStart, false},
          {Credo.Check.Refactor.RedundantWithClauseResult, false},
          {Credo.Check.Refactor.UnlessWithElse, false},
          {Credo.Check.Refactor.WithClauses, false}
        ],
        extra: [
          {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
          {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 10]}
        ]
      }
    }
  ]
}
