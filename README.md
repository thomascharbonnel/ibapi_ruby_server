# IBKR Ruby

Connect to IBKR's TWS API to extract your account's positions.

This uses jruby and isn't meant for real-world use, hence the awful code.

Code: read the java sample rfq

# Find and install TwsApi.jar

Find TwsApi.jar from IBKR and move into `./lib/java/`.

# Starting the IB Gateway

```bash
ssh -Y debianvm
ibgateway
jruby ./app.rb
```
