UPDATE i2b2crcdata.observation_fact
SET valtype_cd='T', nval_num=NULL, tval_char=to_char(nval_num,'00000')
WHERE concept_cd='AKTIN:ZIPCODE' AND nval_num IS NOT NULL