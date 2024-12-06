# debian-i2b2-pkg

This Debian package extends the [AKTIN i2b2 installation](https://github.com/aktin/debian-i2b2-pkg) with DWH (Data Warehouse) capabilities for emergency department data management. It provides data import functionality, reporting tools, and integration with the AKTIN broker network.

## Prerequisites
- AKTIN i2b2 package (version ≥ 1.6)
- Python 3
- R with required packages:
    - tidyverse
    - lattice
    - xml
- Python dependencies:
    - numpy
    - pandas
    - plotly
    - psycopg2
    - sqlalchemy
    - gunicorn

## Installation
```bash
sudo dpkg -i aktin-notaufnahme-dwh_<version>.deb
sudo apt-get install -f  # Install missing dependencies if any
```

## Components
- AKTIN DWH J2EE Application
- P21 import scripts for data ingestion
- Apache reverse proxy configuration
- Database extensions for i2b2
- Reporting system integration

## Configuration
- Main configuration file: `/etc/aktin/aktin.properties`
- Import scripts location: `/var/lib/aktin/import-scripts`
- Data directories:
    - Import: `/var/lib/aktin/import`
    - Reports: `/var/lib/aktin/reports`
    - Broker: `/var/lib/aktin/broker`

## Building
```bash
./build.sh [--cleanup] [--skip-deb-build]
```
Options:
- `--cleanup`: Remove build directory after package creation
- `--skip-deb-build`: Skip the Debian package build step

## Key Features
- Integration with AKTIN broker network
- P21 data import functionality
- Automated reporting system
- i2b2 database extensions for emergency department data
- Email notification system
- Data archiving capabilities

## Maintenance Scripts
- `preinst`: Configures DWH before unpacking
- `postinst`: Configures DWH after installation
- `prerm`: Prepares system for package removal
- `postrm`: Cleans up after package removal
- Integration with i2b2 helper scripts

## Support
For support, contact: [it-support@aktin.org](mailto:it-support@aktin.org)

Homepage: https://www.aktin.org/
