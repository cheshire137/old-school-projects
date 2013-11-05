function form_fixer() {
  var forms = document.getElementsByTagName( 'form' )
  var labels, form, label, content, span, width
  
  // Regular expression to test for the CSS class 'full'
  // on an HTML tag
  var full_regex = new RegExp( 'full', 'i' )
  
  for ( var i=0; i<forms.length; i++ ) {
    form = forms[i]
    form.style.display = 'none'
    labels = form.getElementsByTagName( 'label' )

    for ( var j=0; j<labels.length; j++ ) {
      label = labels[j]
      
      // If the label has a CSS class of "full", we want
      // to skip it because the label should take up the
      // full width of its area
      if ( full_regex.test( label.className ) )
        continue;
      
      content = label.innerHTML
      width = document.defaultView.getComputedStyle( label, '' ).getPropertyValue( 'width' )
      span = document.createElement( 'span' )
      span.style.display = 'block'
      span.style.width = width
      span.innerHTML = content
      label.style.display = '-moz-inline-box'
      label.innerHTML = null
      label.appendChild( span )
    }

    form.style.display = 'block'
  }
}

function hider() {
  var hide = new RegExp( 'hide' )
  var show = new RegExp( 'show' )
  var elements = document.getElementsByTagName('*')

  for ( var i=0; i<elements.length; i++ ) {
    if ( hide.test( elements[i].className ) && !show.test( elements[i].getAttribute( 'rel' ) ) )
      Element.hide( elements[i] )
  }
}

function toggle_display( id, curr_element ) {
  var element = document.getElementById( id )
  var image = curr_element.getElementsByTagName( 'img' )[0]
  var hide_regex = new RegExp( 'plus.gif' )
  var show_regex = new RegExp( 'minus.gif' )
  curr_element.blur()

  if ( element.className == 'hide' ) {
    Element.show( element )
    element.className = 'show'
    image.src = image.src.replace( hide_regex, 'minus.gif' )
  } else {
    Element.hide( element )
    element.className = 'hide'
    image.src = image.src.replace( show_regex, 'plus.gif' )
  }
  
  return false
}

// We only need to "fix" the forms for Mozilla-based browsers,
// so we use the Mozilla-specific document.addEventListener
// method
if( document.addEventListener )
  document.addEventListener( 'DOMContentLoaded', form_fixer, false )

Event.observe( window, 'load', function() {
  hider()
} );
