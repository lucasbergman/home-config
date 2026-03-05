{
  lib,
  stdenv,
  fetchurl,
  libmilter,
  spamassassin,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "spamass-milter";
  version = "0.4.0";

  src = fetchurl {
    url = "mirror://savannah/spamass-milt/spamass-milter-${finalAttrs.version}.tar.gz";
    hash = "sha256-eC8bs7CKBEfNUa1LZOdQaSZzn6nM5TfzzGKqmyTUawc=";
  };

  # Debian patches, in order from debian/patches/series
  patches = [
    # Add -I option to ignore authenticated senders
    ./patches/ignore_by_smtp_auth.patch
    # Fix spacing issues in generated Received header
    ./patches/fix_spacing_in_received_header.patch
    # Add auth info to generated Received header
    ./patches/auth_in_received.patch
    # Remove queue ID from ENVRCPT callback (use mlfi_eom instead)
    ./patches/queueid_in_envrcpt.patch
    # Fix CRLF handling in folded headers
    ./patches/crlf_in_generated_header.patch
    # Add -g option for group-writable socket (needed for Postfix)
    ./patches/socket_gid.patch
    # Synthesize macro $b using current time (required for sendmail compatibility)
    ./patches/synthesize_macro_b.patch
  ];

  buildInputs = [ libmilter ];

  # Tell configure where to find spamc and sendmail (used at runtime)
  SPAMC = "${spamassassin}/bin/spamc";
  SENDMAIL = "/run/wrappers/bin/sendmail"; # NixOS sendmail wrapper location

  meta = {
    homepage = "https://savannah.nongnu.org/projects/spamass-milt/";
    description = "Sendmail milter for SpamAssassin";
    longDescription = ''
      spamass-milter is a sendmail milter that pipes all incoming mail
      through SpamAssassin, a highly customizable spam filter.
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
    mainProgram = "spamass-milter";
    maintainers = [ lib.maintainers.lucasbergman ];
  };
})
