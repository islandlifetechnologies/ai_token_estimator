Simple CLI that utilizes the [bpe](https://pub.dev/packages/bpe) package to scan code and output the estimated token count to a `TOKEN_ESTIMATE.md` file. Please note, these numbers are only estimates as the actual numbers vary by model. In general the numbers can be used as relative numbers to determine if one code base consumes more or less tokens than another, but should never be used as absolute values.

While this may work for other languages, it is designed and tested for Dart based code. By default, it only scans the dart files contained within the `lib` folders of the folder and sub folders. This can be overridden by changing the `--pattern` CLI arg.

## Usage

Installing

```bash
dart pub global activate ai_token_estimator
```

For help run:

```bash
ai_token_estimator --help
```
