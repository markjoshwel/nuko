# nuko

nuko is a small file uploader to <catbox.moe> and <litterbox.catbox.moe>.

it is also an exercise in learning and writing [Zig](https://ziglang.org/).

## installing

TODO

## usage

> [!NOTE]  
> album creation and management is not implemented yet.

```text
usage: nuko [-h] [-l] [-t {1,12,24,72}] [file, ...]

a small file uploader to [litter.]catbox.moe

positional arguments:
  file                path(s) to file to read

optional arguments:
  -h, --help          show this help message and exit
  -v, --version       show program's version number and exit
  -l, --litterbox     use litterbox.catbox.moe instead of catbox.moe
  -t {1,12,24,72}, --time {1,12,24,72}
                      (for litterbox) how long the file should be kept
  -u USERHASH, --userhash USERHASH
                      (for catbox) specify a userhash for non-anonymous uploads
  -a [SHORT], --album [SHORT]
                      (for catbox) create a new album if short is not specified
                      add an '/edit' '/add' or 'remove' suffix to edit images,
                      add images to and remove images from an already existing
                      album respectively. 
                      when given, files parameter are shorts of files already on
                      catbox.

                      shorts are the short identifiers of catbox files.
                      e.g., the short of 'https://files.catbox.moe/0k6bpc.jpg'
                      is '0k6bpc.jpg'
                      same goes for albums, but without the preceding '.../c/'
```

### examples

> [!NOTE]  
> the command line parsing in nuko is written from scratch, and as such is not thorough.  
> chaining of flags such as `-lt` is not supported.

1. upload a file to catbox.moe anonymously

   ```text
   nuko file.webm
   ```

2. upload a file to litter.catbox.moe anonymously

   ```text
   nuko -l file.webm
   ```

3. upload a file to litter.catbox.moe anonymously and set an expiration of 24 hours

   ```text
   nuko -l -t 24 file.webm
   ```

4. make an album on catbox.moe with two files

   > [!IMPORTANT]  
   > albums can only be modified if a userhash is given.

   ```text
   nuko -a -u a_unique_user_hash 7lbgmz.jpg wgg3yb.jpg v7u0xs.jpg
   ```

5. remove an image from an album on catbox.moe

   > [!NOTE]  
   > when an album has a modification suffix like `/edit`, `/add` and `remove`, files
   > given to nuko are treated as shorts (shortened versions of a catbox URL) of files
   > already on catbox.

   ```text
   nuko -a v90wjs/remove -u a_unique_user_hash 7lbgmz.jpg
   ```

note on album modification suffixes:

- `/edit` is used to completely change the contents of an album, the list of shorts
  given to nuko will be the new contents of the album.

- `/add` is used to add files to an album, the list of shorts given to nuko will be
  added to the album.

- `/remove` is used to remove files from an album, the list of shorts given to nuko
  will be removed from the album.

## developing

TODO

### licence

nuko is free and unencumbered software released into the public domain. For more
information, please refer to <http://unlicense.org/> or the [UNLICENCE](UNLICENCE) file.
