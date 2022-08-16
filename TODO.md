# backdrop-systemd to-do list

* [ ] Improve tests so that they check if service is active as a
      pass. On failure they could open a shell if an
      `EXPLORE_CONTAINER` variable is set.
* [ ] Consider some kind of test framework to manage the running of
      the tests.
* [ ] Create a Makefile for local installation.
* [ ] Add `backdrop-maintenance`timer service which runs maraidb-repair and
      mariadb-optimise along with any other tasks?
* [ ] Add `backdrop-cron` timer service.
* [ ] Add `backdrop-backup` timer service. This could have a number of
      backends for performing snapshots e.g. BTRFS, LVM, etc.
