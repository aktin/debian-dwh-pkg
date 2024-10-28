-- This sets the `update_date` and `download_date` columns to match the `import_date` for all rows where the `provider_id` is 'P21'.
-- This ensures that the generation of monthly aktin reports does not throw an exception if p21 data is included as the old version of the p21
-- import script did not set a corresponding update or download data.

UPDATE i2b2crcdata.observation_fact
SET update_date = import_date, download_date = import_date
WHERE provider_id='P21';
