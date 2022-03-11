# Please build your own test file from test-template.R, and place it in tests folder
# please specify the package you need to run the sim function in the test files.

# to test all the test files in the tests folder:
testthat::test_dir(file.path("tests", "testthat"))

# Alternative, you can use test_file to test individual test file, e.g.:
testthat::test_file(file.path("tests", "testthat", "test-template.R"))
