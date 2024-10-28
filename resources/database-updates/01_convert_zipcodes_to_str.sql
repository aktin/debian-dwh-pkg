-- Update the observation_fact table in the i2b2crcdata schema to standardize ZIP code values from a previously stored integer format to a string format.
-- In the old numeric storage, leading zeros were removed from ZIP codes, causing issues and requiring corrections during data analysis.
-- This update addresses that by converting ZIP codes to a 5-character string with leading zeros if necessary.

UPDATE i2b2crcdata.observation_fact
SET valtype_cd='T', nval_num=NULL, tval_char=to_char(nval_num,'00000')
WHERE concept_cd='AKTIN:ZIPCODE' AND nval_num IS NOT NULL;
