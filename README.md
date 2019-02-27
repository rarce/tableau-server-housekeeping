# Install instructions

Clone this repo:
```
git clone https://github.com/rarce/tableau-server-housekeeping.git
```

Setup credentials in `.aws/credentials` and install awscli

```
sudo yum install awscli
```

Edit and copy config:
```
sudo cp tableau-server-housekeeping/tableau-server-housekeeping.cfg.example /etc/tableau-server-housekeeping.cfg
sudo vim /etc/tableau-server-housekeeping.cfg
```

Run install script
```
cd tableau-server-housekeeping
./install-script.sh
```