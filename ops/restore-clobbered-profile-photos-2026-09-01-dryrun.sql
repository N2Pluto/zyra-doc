-- Dry run for restore-clobbered-profile-photos-2026-09-01.sql (ZYR-1137)
-- READ-ONLY. Prints exactly which rows the restore would change.
--   cd zyra-service && ./prod-db.sh up
--   ./prod-db.sh file ../zyra-doc/ops/restore-clobbered-profile-photos-2026-09-01-dryrun.sql
-- Verified against prod 2026-09-01: 20 rows. After a successful restore it
-- must return 0 rows.

WITH restore AS (
  SELECT * FROM unnest(
    ARRAY[
      '115028431167634690253',  -- bank_cs@hpktechnology.com
      '103752357838425626890',  -- earth@hpktechnology.com
      '106734779563103240834',  -- game.ponlawat.lk@gmail.com
      '114710646999584000790',  -- golf_cs@hpktechnology.com
      '108806782911710212465',  -- got@hpktechnology.com
      '101723365981231139232',  -- ja@hpktechnology.com
      '108197476978042434448',  -- jane@hpktechnology.com
      '104384864193884835486',  -- jeen@hpktechnology.com
      '106267992371767285770',  -- oat_cs@hpktechnology.com
      '114268955522643145535',  -- pai@hpktechnology.com
      '103952702312807936290',  -- peach_cs@hpktechnology.com
      '112252141017865433425',  -- pingpong@hpktechnology.com
      '113172330282123238746',  -- poom@hpktechnology.com
      '110074316931454934536',  -- pup@hpktechnology.com
      '103134934857741802484',  -- ruj_cs@hpktechnology.com
      '114888162231853318116',  -- team@hpktechnology.com
      '110677565880933217950',  -- tonkaow@hpktechnology.com
      '115392199739487488358',  -- trust_uxui@hpktechnology.com
      '117823013644039203444',  -- tum@hpktechnology.com
      '117232243441271657694'  -- witsanu.sj@gmail.com
    ],
    ARRAY[
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/115028431167634690253/5e2633b0-3d80-452d-893e-b0c310be2faf.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/103752357838425626890/38685c89-3665-4437-9c81-c0b647050fb3.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/106734779563103240834/f3e6640e-bad3-472f-a7d3-5f5f3072dd79.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/114710646999584000790/bd4c86e2-1b2c-4280-81a3-8648465c1ec5.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/108806782911710212465/e06becc9-20db-430b-b94d-d3c14b83294b.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/101723365981231139232/f386faf3-cb72-4529-82be-13e9cfa0ec82.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/108197476978042434448/df303839-cb29-4670-b22d-63820507d020.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/104384864193884835486/724d45fa-081a-4e9c-9ebe-ee1063c56da2.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/106267992371767285770/db0c4514-af2c-435c-bdf1-c13077e87474.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/114268955522643145535/6e28efeb-cadf-4c50-bbd5-c4fd6ea813ba.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/103952702312807936290/8bc9bd6e-152e-45d2-b567-9bc2c0cdd613.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/112252141017865433425/8a1c313a-bd6a-487f-b13e-2b7dc347a888.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/113172330282123238746/d20d3903-cdf4-47f6-bb4f-11f3491f82df.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/110074316931454934536/5548b378-a3ab-4e37-94f0-aee43af3442a.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/103134934857741802484/025eba53-1066-4eaa-84e5-e2d4e6413091.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/114888162231853318116/764df557-06fa-4002-adc3-182c90c98100.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/110677565880933217950/d3a1260a-86f0-4fc3-aa32-8c6584a45564.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/115392199739487488358/735eb574-7e41-4595-97f8-efc1b486f53d.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/117823013644039203444/1f35aa94-368d-4573-af7a-ff32d31375af.jpg',
      'https://storage.googleapis.com/zyra-prod-gather-dev-458614/profiles/117232243441271657694/bd87c31f-e2b0-4250-a1ed-0a3131468081.jpg'
    ]
  ) AS t(user_id, photo_url)
)
SELECT u.email, left(u.image_upload, 28) AS current_value, right(r.photo_url, 18) AS would_restore
  FROM restore r JOIN tb_user u ON u.id = r.user_id
 WHERE u.image_upload LIKE '%googleusercontent%'
 ORDER BY u.email;
