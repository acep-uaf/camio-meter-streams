# data-ducks-STREAM



![](data-ducks-stream.png)

run 
```bash
docker-compose up -d
``` 

Access the InfluxDB UI:
Open a web browser and navigate to http://localhost:8086. You should be greeted with a setup screen. SET UP FOR influxdb v2 you will need a org and a bucket and token. you must complete the set up. 


create a .env and add the org, token, and bucket to the .env file. 

```bash
INFLUX_TOKEN=paste-your-token-here
INFLUX_ORG=org-name
INFLUX_BUCKET=bucket-name

```

If you look in the telegraf.conf file you will see the configurations for the influxdb-v2. Take a look in the file.

Access Grafana: Open http://localhost:3000 on your browser. The default login is usually admin for both username and password.

Add influxdb v2 to grafana as a data source. Make sure the Query Language is Flux (for influxdb v2).

