Template.Index.onCreated ->
  @searchValue = new ReactiveVar()
  @autorun =>
    @subscribe 'latest', @searchValue.get()
