# Contributing to vim-mermaid-ascii

Thank you for your interest in contributing to vim-mermaid-ascii!

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/normen/vim-mermaid-ascii.git
cd vim-mermaid-ascii
```

2. Install mermaid-ascii binary:
```bash
curl -s https://api.github.com/repos/AlexanderGrooff/mermaid-ascii/releases/latest | \
  grep "browser_download_url.*mermaid-ascii" | \
  grep "$(uname)_$(uname -m)" | \
  cut -d: -f2,3 | tr -d \" | wget -qi -
tar xvzf mermaid-ascii_*.tar.gz
sudo mv mermaid-ascii /usr/local/bin/
```

3. Link the plugin to your Vim configuration for testing:
```bash
# For Vim
ln -s $(pwd) ~/.vim/bundle/vim-mermaid-ascii

# For Neovim
ln -s $(pwd) ~/.local/share/nvim/site/pack/plugins/start/vim-mermaid-ascii
```

## Testing

Run the test script to create a sample file:
```bash
./test.sh
```

Then open the test file in Vim:
```bash
vim test_diagram.md
```

Test the commands:
- `:MermaidAsciiRender` - Should render mermaid blocks
- `:MermaidAsciiUnrender` - Should restore original code
- Move cursor into/out of rendered blocks to test auto-rendering

## Project Structure

```
vim-mermaid-ascii/
├── plugin/mermaid_ascii.vim    # Main plugin file (commands, mappings, config)
├── autoload/mermaid_ascii.vim  # Autoloaded functions (core logic)
├── doc/mermaid-ascii.txt       # Vim documentation
├── README.md                   # User documentation
├── LICENSE                     # MIT License
├── examples.md                 # Example mermaid diagrams
└── test.sh                     # Test script
```

## Code Style

- Follow standard VimScript conventions
- Use 2 spaces for indentation
- Comment complex logic
- Keep functions focused and single-purpose

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Reporting Bugs

Please open an issue with:
- Vim/Neovim version
- mermaid-ascii version
- Steps to reproduce
- Expected vs actual behavior
- Example mermaid code that causes the issue

## Feature Requests

Feature requests are welcome! Please open an issue describing:
- The feature you'd like to see
- Why it would be useful
- How you envision it working

Thank you for contributing!
