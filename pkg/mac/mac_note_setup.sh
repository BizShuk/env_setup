# notice
# .bashrc will not execute , but .bash_profile will



`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`


# git
brew install git 

# nodejs
brew install nvm
echo "source $(brew --prefix nvm)/nvm.sh" >> ~/.bash_profile
source .bash_profile
# need to restart terminal or source .bash_profile
