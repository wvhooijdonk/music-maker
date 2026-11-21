sudo apt-get update
sudo apt-get install -y unzip xz-utils
git clone https://github.com/flutter/flutter.git -b stable /home/vscode/flutter
/home/vscode/flutter/bin/flutter config --no-analytics --enable-web
/home/vscode/flutter/bin/flutter precache --web
