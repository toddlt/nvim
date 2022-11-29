# neovim 配置

## 运行环境配置

```shell
git clone https://github.com/toddlt/nvim ~/.config/nvim

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 
cd ~/.config && python3 -m venv python-nvim

cd $HOME && ./.config/python-nvim/bin/python3 -m pip install pynvim
```

## 检查运行状态 

```vim
#install the plugin
:PackerSync
#ensure neovim work properly
:checkheath
```
