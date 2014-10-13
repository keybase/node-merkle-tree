##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEcBAABAgAGBQJUPCLLAAoJEJgKPw0B/gTfWOkH/RJR3HCSJn5GU5cmC/wku5F3
zb2C++L0l5av4N7VbhkgK/QnWOUGz6vv1ploWud53RtKG0/JBzpDZ1U/fm7uSlDQ
G2p6BSPK+jdcIv03Gkriy4763+JUPcCbH4XaUmT3u2B9lmlOoar9dCuLY0UUJvxi
Zld5ByXfcy37K3sxxQNBu+XnzXTr1G3tyEFCjga7HYuyJD2z6GwEfbT/hTP10uhH
vXIGeQIucts3/7ZYr7SBSHP/MPGJlvOPjMk8jyBtS8lbOTfIh5+NCDwKVJS58pCD
eaMXt5+9Pm7OnWw0p14Y3giE4Y2ciECcDzMtJhf8Dcd9F6mU486bSu3CC4NfeOM=
=W36o
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                     contents                                                        
             ./                                                                                       
547            .gitignore             a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
554            CHANGELOG.md           14859a17246ff3ab4fb81953595e5a681c968ac94bc6c14c087610f4986974b5
1482           LICENSE                9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
393            Makefile               069be562c87112459ea09e88b442355fb08ffdbacb38c9acc35f688f7bc75e09
3618           README.md              490ce837ca7f2b98cd092034fdc8aaf0a8c67d19141c55abd80c3b7763b0b087
               lib/                                                                                   
299              main.js              40ca05af21bfbdfe551411d5c492aaeb8d405ae11055875c1bcdf474edd62b9f
1932             mem.js               c23ce8608a17e23371e52b3b80e87441e93bcd802b11f8ea7493e259d22f8543
33295            tree.js              d1c074fa02c0361a5c06c2e466f0406459ee4254e814cff8a93f5c3a53cf2d06
838            package.json           d34861757b6972c9e3314e9bdd826292b97928f729ef376ead2e47937b1280a7
               src/                                                                                   
104              main.iced            f52112db1bdab29276374d4f4d39eab83c1b0a8db2955dc0e23aadbfb43d4b47
1011             mem.iced             f4f664a2e82498a312f59a6ae72caf3a5e4cc136be7967e88398e44f6b8de34b
10538            tree.iced            be0201b8a8622fd85f32550550cd1bcca10d731ab9c05329f4ce65a420975482
               test/                                                                                  
                 files/                                                                               
2118               0_simple.iced      5ecbf097a879d9aacf951511b7c2a81e8d405c13704df4d7cd56baaf2aeb2660
1987               1_bushy.iced       a49b51258e8973ba358cf5e2fae8b66ca6b6a18f2635b97d09c75604a026cb21
1779               2_one_by_one.iced  7bb8910e8dedbc46454f76904379f9dbfcb75ffd9af56be67f97967409da086d
690                obj_factory.iced   ceddef906435b35a9ff0436b8900bb8b92d036e0d24222e10d62c933c3d7e47e
53               run.iced             79bcb89528719181cafeb611d8b4fdfa6b3e92959099cbb4becd2a23640d38df
```

#### Ignore

```
/SIGNED.md
```

#### Presets

```
git      # ignore .git and anything as described by .gitignore files
dropbox  # ignore .dropbox-cache and other Dropbox-related files    
kb       # ignore anything as described by .kbignore files          
```

<!-- summarize version = 0.0.9 -->

### End signed statement

<hr>

#### Notes

With keybase you can sign any directory's contents, whether it's a git repo,
source code distribution, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase dir verify
```

There are lots of options, including assertions for automating your checks.

For more info, check out https://keybase.io/docs/command_line/code_signing