# Local release contact configuration

Personal contact and legal-identification values used during store submission
must not be committed to this repository.

1. Copy `config/app-submission.env.example` to
   `config/app-submission.local.env`.
2. Fill in the local file with the account holder's real values.
3. Resolve the `${VARIABLE_NAME}` placeholders in store-submission documents
   only while entering data into App Store Connect or Play Console.
4. Never paste resolved values back into tracked documentation, issue text,
   release notes, screenshots, logs, or build artifacts.

The local file is explicitly ignored by `.gitignore`. Before committing release
documentation, stage the intended files and run the private-value guard:

```sh
git check-ignore -v config/app-submission.local.env
scripts/check-private-release-values.sh
```

The guard reads each identifying value from the ignored local file and fails if
that value appears in a tracked or unignored file. It reports only the variable
and offending path, not the private value.

The existing bundle, entitlement, background-task, and Worker host identifiers
contain the legacy public namespace `dev.tomhess` or `tomhess.workers.dev`.
Those values are already public application identifiers rather than submission
contact data. They must remain literal because changing them would break app
identity, signing, deep links, cloud containers, widgets, or the production API.

The variables are:

- `${APP_SUPPORT_EMAIL}`: customer-support contact used in store listings.
- `${APP_PRIVACY_CONTACT_EMAIL}`: privacy and deletion-request contact.
- `${SECURITY_CONTACT_EMAIL}`: private security contact.
- `${APP_STORE_REVIEW_FIRST_NAME}` and `${APP_STORE_REVIEW_LAST_NAME}`: App
  Review contact name.
- `${APP_STORE_REVIEW_EMAIL}` and `${APP_STORE_REVIEW_PHONE}`: App Review
  contact details. Use E.164 format for the phone number.
- `${APP_STORE_COPYRIGHT_HOLDER}`: legal rights holder entered in App Store
  Connect.
- `${APP_STORE_SUPPORT_URL}`: public support page used in store listings.
- `${GOOGLE_DRIVE_TEST_ACCOUNT_EMAIL}`: private Google Drive setup tester.
