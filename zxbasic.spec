# -*- mode: python -*-

block_cipher = None


zxb_a = Analysis(['zxb.py'],
             pathex=['/Users/boriel/Documents/src/zxbasic'],
             binaries=[],
             datas=[],
             hiddenimports=['parsetab'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)

zxbasm_a = Analysis(['zxbasm.py'],
             pathex=['/Users/boriel/Documents/src/zxbasic'],
             binaries=[],
             datas=[],
             hiddenimports=['parsetab'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,

             cipher=block_cipher)

zxbpp_a = Analysis(['zxbpp.py'],
             pathex=['/Users/boriel/Documents/src/zxbasic'],
             binaries=[],
             datas=[],
             hiddenimports=['ply', 'parsetab'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)

MERGE( (zxb_a, 'zxb', 'zxb'), (zxbasm_a, 'zxbasm', 'zxbasm'), (zxbpp_a, 'zxbpp', 'zxbpp') )

zxb_pyz = PYZ(zxb_a.pure, zxb_a.zipped_data,
             cipher=block_cipher)
zxb_exe = EXE(zxb_pyz,
          zxb_a.scripts,
          exclude_binaries=True,
          name='zxb',
          debug=False,
          strip=False,
          upx=True,
          console=True )
zxb_coll = COLLECT(zxb_exe,
               zxb_a.binaries,
               zxb_a.zipfiles,
               zxb_a.datas,
               strip=False,
               upx=True,
               name='zxb')

zxbasm_pyz = PYZ(zxbasm_a.pure, zxbasm_a.zipped_data,
             cipher=block_cipher)
zxbasm_exe = EXE(zxbasm_pyz,
          zxbasm_a.scripts,
          exclude_binaries=True,
          name='zxbasm',
          debug=False,
          strip=False,
          upx=True,
          console=True )
zxbasm_coll = COLLECT(zxbasm_exe,
               zxbasm_a.binaries,
               zxbasm_a.zipfiles,
               zxbasm_a.datas,
               strip=False,
               upx=True,
               name='zxbasm')

zxbpp_pyz = PYZ(zxbpp_a.pure, zxbpp_a.zipped_data,
             cipher=block_cipher)
zxbpp_exe = EXE(zxbpp_pyz,
          zxbpp_a.scripts,
          exclude_binaries=True,
          name='zxbpp',
          debug=False,
          strip=False,
          upx=True,
          console=True )
zxbpp_coll = COLLECT(zxbpp_exe,
               zxbpp_a.binaries,
               zxbpp_a.zipfiles,
               zxbpp_a.datas,
               strip=False,
               upx=True,
               name='zxbpp')

