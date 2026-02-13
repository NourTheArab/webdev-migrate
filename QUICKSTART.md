# webdev-migrate Quick Start Guide

**Get started in 5 minutes!**

## Installation

```bash
# 1. Copy the script
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate

# 2. Install prerequisites
sudo apt update && sudo apt install -y \
    mysql-client \
    wordpress-cli \
    apache2 \
    rsync \
    openssh-client \
    gzip \
    tar

# 3. Create log directory
sudo mkdir -p /var/log/webdev-migrate
sudo chown $USER:$USER /var/log/webdev-migrate

# Done!
```

## First Run

```bash
webdev-migrate
```

You'll see an interactive menu. Try option 1 (Inventory) to explore a site.

## Common Tasks

### Check a site
```bash
webdev-migrate inventory portfolios.cs.earlham.edu
```

### Backup a site
```bash
webdev-migrate backup /var/www/wordpress-portfolios portfolios live
```

### Health check
```bash
webdev-migrate healthcheck portfolios.cs.earlham.edu
```

### Migrate to new server
```bash
# Dry run first
webdev-migrate --dry-run migrate web:portfolios web-urey:portfolios

# Then real migration
webdev-migrate migrate web:portfolios web-urey:portfolios
```

### Create test copy
```bash
webdev-migrate clone-to-test portfolios
```

## Help

```bash
webdev-migrate --help
```

## Documentation

- **README.md** - Complete reference manual
- **TRAINING.md** - Beginner's guide (start here if new)
- **WALKTHROUGHS.md** - Step-by-step examples
- **webdev-migrate.conf.example** - Configuration template

## Support

- Check logs: `/var/log/webdev-migrate/`
- Run with `--verbose` for details
- Use `--dry-run` to test safely
- Contact Nour regarding the tool, or Porter regarding infrastructure.

## Safety Tips

✓ Always backup before changes
✓ Use --dry-run for complex operations
✓ Test on test environment first
✓ Read the logs if something fails
✓ Ask for help when unsure

**Happy migrating!** 
