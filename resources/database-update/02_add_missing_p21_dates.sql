UPDATE i2b2crcdata.observation_fact
SET update_date = import_date, download_date = import_date
WHERE provider_id='P21'