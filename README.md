# clean-marks.nvim
An addition to the global A-Z file marks.

Allows to mark files with multiple characters. These marks are stored in a separate per-project JSON file and do not affect the default marks.
The last character in the mark string must end with a capital letter.

By default a clean mark is set with `<leader>m`. Jump to the mark with `<leader>'`, cursor position is also restored to where it was before leaving the file (using the default `"` mark, so larger shada is recommended).

Borne out of experience with enterprisey .net/java codebases where the default single-char marks tended to underperform.

Some examples:

`OrderController` => `oC` (or `Co`)

`TransactionProcessingEngine` => `tE`

`UserConfigurationRepository` => `ucR`

`XmlSerializationProviderHelper` => `xH`

`AbstractSingletonProxyFactoryBean` => `aspfB`


## Lazy

```lua
{
  "ivfiev/clean-marks.nvim",
  opts = {
    max_length = 4,
    mappings = {
      goto_mark = "<leader>'",
      set_mark = "<leader>m",
      float_window = "<leader>cm",
    },
    window = {
      height = 0.95,
      width = 0.7,
    },
  },
},

```
