class DomainCreationForm extends KDTabViewWithForms

  domainOptions = [
      { title : "Create a subdomain", value : "subdomain" }
      { title : "I want to register a domain", value : "new" }
      { title : "I already have a domain", value : "existing" }
    ]

  constructor:->

    {nickname, firstName, lastName} = KD.whoami().profile

    super
      navigable                       : no
      goToNextFormOnSubmit            : no
      hideHandleContainer             : yes
      forms                           :
        "Domain Address"              :
          callback                    : ->
          buttons                     :
            registerButton            :
              title                   : "Register Domain"
              style                   : "cupid-green hidden"
              type                    : "submit"
              loader                  :
                color                 : "#ffffff"
                diameter              : 24
              callback                : =>
                @registerDomain()
            createButton              :
              title                   : "Add Domain"
              style                   : "cupid-green"
              type                    : "submit"
              loader                  :
                color                 : "#ffffff"
                diameter              : 24
              callback                : =>
                @registerDomain()
            checkButton              :
              title                   : "Check Domain"
              style                   : "cupid-green hidden"
              type                    : "submit"
              loader                  :
                color                 : "#ffffff"
                diameter              : 24
              callback                : =>
                @checkAvailability()

            close                     :
              title                   : "Back to settings"
              style                   : "cupid-green hidden"
              callback                : => @reset()
            cancel                    :
              style                   : "cupid-green"
              callback                : => @emit 'DomainCreationCancelled'
            another                   :
              title                   : "add another domain"
              style                   : "modal-cancel hidden"
              callback                : => @addAnotherDomainClicked()

          fields                      :
            header                    :
              title                   : "Add a domain"
              itemClass               : KDHeaderView
            DomainOption              :
              name                    : "DomainOption"
              itemClass               : KDRadioGroup
              cssClass                : "group-type"
              defaultValue            : "subdomain"
              radios                  : domainOptions
              change                  : =>
                {DomainOption, domainName, domains, regYears, extensionSelect} = @forms["Domain Address"].inputs
                {checkButton, registerButton} = @forms["Domain Address"].buttons
                actionState = DomainOption.getValue()
                domainName.setValue ''
                domainName.getElement().setAttribute 'placeholder', switch actionState
                  when "new"
                    @suggestionBox?.show()
                    # domainName.setValidation domainNameValidation
                    domains.hide()
                    extensionSelect.show()
                    regYears.show()
                    createButton.hide()
                    checkButton.show()
                    registerButton.hide()
                    "#{KD.utils.slugify firstName}s-new-domain.com"
                  when "existing"
                    @suggestionBox?.hide()
                    # domainName.setValidation domainNameValidation
                    domains.hide()
                    extensionSelect.hide()
                    regYears.hide()
                    checkButton.hide()
                    registerButton.hide()
                    createButton.show()
                    "#{KD.utils.slugify firstName}s-existing-domain.com"
                  when "subdomain"
                    # domainName.unsetValidation()
                    @suggestionBox?.hide()
                    extensionSelect.hide()
                    domains.show()
                    regYears.hide()
                    checkButton.hide()
                    registerButton.hide()
                    createButton.show()
                    "#{KD.utils.slugify firstName}s-subdomain"
            domainName                :
              cssClass                : "domain"
              placeholder             : "#{KD.utils.slugify firstName}s-subdomain"
              validate                :
                rules                 :
                  required            : yes
                messages              :
                  required            : "Subdomain name is required!"
              keydown                 :
                =>
                  @clearSuggestions()
                  {DomainOption} = @forms["Domain Address"].inputs
                  actionState = DomainOption.getValue()
                  if actionState is "new"
                    {registerButton, checkButton} = form.buttons
                    registerButton.hide()
                    checkButton.show()
              nextElement             :
                regYears              :
                  cssClass            : "hidden"
                  itemClass           : KDSelectBox
                  selectOptions       : ({title: "#{i} Year#{if i > 1 then 's' else ''}", value:i} for i in [1..10])
                domains               :
                  cssClass            : "domains"
                  itemClass           : KDSelectBox
                  validate            :
                    rules             :
                      required        : yes
                    messages          :
                      required        : "Please select a parent domain."
                extensionSelect       :
                  cssClass            : "domains hidden"
                  itemClass           : KDSelectBox
                  validate            :
                    rules             :
                      required        : yes
                    messages          :
                      required        : "Please select an extension"
            suggestionBox             :
              type                    : "hidden"
    form = @forms["Domain Address"]
    {createButton} = form.buttons

    form.on "FormValidationFailed", createButton.bound 'hideLoader'
    @on "DomainCreationCancelled", createButton.bound 'hideLoader'

  viewAppended:->
    KD.whoami().fetchDomains (err, userDomains)=>
      warn err  if err
      domainList = []
      for domain in userDomains
        if not domain.regYears > 0
          domainList.push {title:".#{domain.domain}", value:domain.domain}
      {domains, extensionSelect} = @forms["Domain Address"].inputs
      domains.setSelectOptions domainList
      availableTldList = ["com", "net", "org"]
      extensionsList = ({title:'.'+ext, value:ext} for ext in availableTldList)
      extensionSelect.setSelectOptions extensionsList
      extensionSelect.setDefaultValue availableTldList[0]

  checkAvailability: ->
    form = @forms["Domain Address"]
    domain            = form.inputs.domainName.getValue()
    tld               = form.inputs.extensionSelect.getValue()
    {createButton, checkButton, registerButton} = form.buttons
    unless domain.match(/^\w+$/)
      notifyUser "Please select the extension from the select box"
      checkButton.hideLoader()
      return
    @clearSuggestions()
    KD.remote.api.JDomain.getTldPrice tld, (tldPrice) => 
      KD.remote.api.JDomain.isDomainAvailable domain, tld, (avErr, status, price, suggestions) =>
      # KD.remote.api.JDomain.isDomainAvailable domain, tld, (avErr, status)=>
        if avErr
          checkButton.hideLoader()
          log domain
          log tld
          log avErr
          log status
          log suggestions
          return notifyUser "An error occured: #{avErr}"
        checkButton.hideLoader()
        switch status
          when "available"
            checkButton.hide()
            registerButton.show()
            @showSuggestions true, price, suggestions
          when "regthroughus", "regthroughothers"
            checkButton.show()
            registerButton.hide()
            @showSuggestions false, price, suggestions 
          when "unknown"
            checkButton.show()
            registerButton.hide()
            notifyUser "Connections are not available. re-check the domain name availability after some time."

  registerDomain: ->
    form = @forms["Domain Address"]
    {createButton, registerButton} = form.buttons
    @clearSuggestions()

    {DomainOption, domainName, regYears, domains, extensionSelect} = form.inputs
    domainInput       = domainName
    domain            = domainName.getValue()
    tld               = extensionSelect.getValue()
    unless domain.match(/^\w+$/)
      notifyUser "Please select the extension from the select box"
      registerButton.hideLoader()
      return
    domainOptionValue = DomainOption.getValue()

    if domainOptionValue is 'new'
        form = @forms["Domain Address"]
        {createButton, registerButton} = form.buttons
        paymentController = KD.getSingleton('paymentController')
        group             = KD.getSingleton("groupsController").getCurrentGroup()
        registerTheDomain = ->
            KD.remote.api.JDomain.registerDomain
              domainName : domainInput.getValue()
              years      : regYears.getValue()
            , (err, domain) =>
              if err
                warn err
                console.log err
                notifyUser "An error occured. Please try again later."
              else
                @showSuccess domain
                domain.setDomainCNameToProxyDomain()
              registerButton.hideLoader()

        paymentController.getBillingInfo 'user', group, (err, account)->
          need = err or not account or not account.cardNumber
          if need
            paymentController.setBillingInfo 'user', group, (success)->
              if success
                registerTheDomain()
          else
            registerTheDomain()


    else if domainOptionValue is 'existing'
      @createDomain {domain, regYears:0, domainType:'existing'}, (err, domain)=>
        createButton.hideLoader()
        if err
          warn err
          if err.message?.indexOf("duplicate key error") isnt -1
            return notifyUser "The domain #{domainName} already exists."
          return notifyUser "Invalid domain #{domainName}.  "
        else
          @showSuccess domain


    else # create a subdomain
      subDomainPattern = /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/
      unless subDomainPattern.test domain
        createButton.hideLoader()
        return notifyUser "#{domainName} is an invalid subdomain."
      domain = "#{domainName}.#{domains.getValue()}"

      @createDomain {domain, regYears:0, domainType:'subdomain'}, (err, domain)=>
        createButton.hideLoader()
        if err
          warn err
          if err.message?.indexOf("duplicate key error") isnt -1
            return notifyUser "The domain #{domainName} already exists."
          return notifyUser "An error occured. Please try again later."
        else
          @showSuccess domain


  createDomain:(params, callback) ->
    console.log params
    KD.remote.api.JDomain.createDomain
        domain         : params.domainName
        regYears       : params.regYears
        proxy          : { mode: 'vm' }
        hostnameAlias  : []
        domainType     : params.domainType
        loadBalancer   :
            # mode       : "roundrobin"
            mode         : ""
      , (err, domain)=>
        callback err, domain

  clearSuggestions:-> @suggestionBox?.destroy()

  showSuggestions:(available, price, suggestions) ->
    @clearSuggestions()

    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    if not available
      partial         = "<p>This domain is already registered. #{if suggestions.length > 0 then 'You may click and try one below.' else ''}</p>"
    else
      partial         = "<p>Domain price is: #{price}$</p>"

    for domain in suggestions
        partial += "<li class=''>#{domain.domain}</li><i>#{domain.price}$</i>"

    suggestionBox.addSubView @suggestionBox = new KDCustomHTMLView
      tagName : 'ul'
      cssClass: 'suggestion-box'
      partial : partial
      click   : (event)->
        domainName.setValue $(event.target).closest('li').text()

  showSuccess:(domain) ->
    @clearSuggestions()
    form            = @forms["Domain Address"]
    {domainName, extensionSelect}    = form.inputs
    {suggestionBox} = form.fields
    {close, createButton, cancel, another} = form.buttons

    close.show()
    another.show()
    createButton.hide()
    cancel.hide()

    @emit 'DomainSaved', domain

    suggestionBox.addSubView @successNote = new KDCustomHTMLView
      tagName : 'p'
      cssClass: 'success'
      # the following partial will vary depending on the DomainOption value.
      # Users who registered a domain through us won't need this change.
      # partial : "<b>Thank you!</b><br>Your domain #{domainName.getValue()} has been added to our database. Please go to your provider's website and add a CNAME record mapping to kontrol.in.koding.com."

      # change this part when registering is there.
      partial : "<b>Thank you!</b><br>Your subdomain <strong>#{domainName.getValue()}.#{extensionSelect.getValue()}</strong> has been added to our database. You can dismiss this panel and point your new domain to one of your VMs on the settings screen."
      click   : => @reset()


  reset:->
    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    {close, createButton, cancel, another} = form.buttons

    close.hide()
    another.hide()
    createButton.show()
    cancel.show()
    @successNote.destroy()
    delete @successNote
    domainName.setValue ''
    @emit 'CloseClicked'

  addAnotherDomainClicked:->
    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    {close, createButton, cancel, another} = form.buttons

    close.hide()
    another.hide()
    createButton.show()
    cancel.show()
    @successNote.destroy()
    delete @successNote
    domainName.setValue ''
    domainName.setFocus()

  notifyUser = (msg) ->
    new KDNotificationView
      type     : 'tray'
      title    : msg
      duration : 5000