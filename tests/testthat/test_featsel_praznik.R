context("filterFeatures_praznik")

test_that("filterFeatures_praznik", {
  a = c(1, 2, 5.3, 6, -2, 4, 8.3, 9.2, 10.1) # numeric vector
  b = c("one", "two", "three") # character vector
  c = c(TRUE, TRUE, TRUE, FALSE, TRUE, FALSE) # logical vector
  d = c(1L, 3L, 5L, 7L, 9L, 17L)
  f = rep(c("c1", "c2"), 9)
  df = data.frame(a = a, b = b, c = c, d = d, f = f, const1 = f, const2 = a)
  df = convertDataFrameCols(df, logicals.as.factor = TRUE)
  task = makeClassifTask(data = df, target = "f")

  candidates = as.character(listFilterMethods()$id)
  candidates = candidates[startsWith(candidates, "praznik_")]
  for (candidate in candidates) {
    fv = generateFilterValuesData(task, method = candidate, nselect = 2L)
    expect_class(fv, "FilterValues")
    expect_data_frame(fv$data, nrow = getTaskNFeats(task))
    expect_set_equal(fv$data$name, getTaskFeatureNames(task))
    expect_equal(sum(!is.na(fv$data[[candidate]])), 2L)
    expect_numeric(fv$data[[candidate]], lower = 0, upper = 1, all.missing = FALSE)

    lrn = makeLearner("classif.featureless")
    lrn = makeFilterWrapper(learner = lrn, fw.method = candidate, fw.abs = 3L)
    res = resample(learner = lrn, task = binaryclass.task, resampling = hout, measures = list(mmce, timetrain), extract = getFilteredFeatures, show.info = FALSE)
    expect_length(res$extract[[1L]], 3L)
  }
})

test_that("FilterWrapper with praznik mutual information, resample", {
  candidates = as.character(listFilterMethods()$id)
  candidates = candidates[startsWith(candidates, "praznik_")]
  lapply(candidates, function(x) {

    lrn1 = makeLearner("classif.lda")
    lrn2 = makeFilterWrapper(lrn1, fw.method = x, fw.perc = 0.5)
    m = train(lrn2, binaryclass.task)
    expect_true(!inherits(m, "FailureModel"))
    expect_equal(m$features, getTaskFeatureNames(binaryclass.task))
    lrn2 = makeFilterWrapper(lrn1, fw.method = "FSelector_chi.squared", fw.abs = 0L)
    m = train(lrn2, binaryclass.task)
    expect_equal(getLeafModel(m)$features, character(0))
    expect_true(inherits(getLeafModel(m)$learner.model, "NoFeaturesModel"))
    lrn2 = makeFilterWrapper(lrn1, fw.method = x, fw.perc = 0.1)
    res = makeResampleDesc("CV", iters = 2)
    r = resample(lrn2, binaryclass.task, res)
    expect_true(!any(is.na(r$aggr)))
    expect_subset(r$extract[[1]][[1]], getTaskFeatureNames(binaryclass.task))
  })
})

test_that("FilterWrapper with praznik mutual information, resample", {
  # wrapped learner with praznik on binaryclass.task
  lrn = makeFilterWrapper(makeLearner("classif.randomForest"), fw.method = "praznik_MIM", fw.abs = 2)
  mod = train(lrn, binaryclass.task)
  feat.imp = getFeatureImportance(mod)$res
  expect_data_frame(feat.imp, types = rep("numeric", getTaskNFeats(binaryclass.task)),
    any.missing = FALSE, nrows = 1, ncols = getTaskNFeats(binaryclass.task))
  expect_equal(colnames(feat.imp), mod$features)
})
