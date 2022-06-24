with import <nixpkgs> {};

pkgs.neovim.override {
  vimAlias = true;
  configure = {
    packages.myVimPackage = with pkgs.vimPlugins; { start = [
      vim-airline
      hoogle
      fzf-vim
      ghcmod
      agda-vim
      papercolor-theme
      vim-easy-align
      vim-nix
      vim-markdown
      rainbow
      vimoutliner
      gv # git commit browser
      surround
      repeat

      neco-ghc # omnicompletion
      vimux    # tmux integration
    ]; };
    customRC = ''source ${./dotfiles/vimrc.vim}'';
  };
}
