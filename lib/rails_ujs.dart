import 'dart:html';
import 'dart:async';
import 'dart:js';

class RailsUjs {
  String csrf_token;
  String csrf_param;
  
  RailsUjs() {
    _initCsrf();
    document.onClick.listen(_clickHandler);
  }
  
  bool _initCsrf() {
    Element csrf_tag = document.querySelector('meta[name="csrf-token"]');
    Element csrf_param_tag = document.querySelector('meta[name="csrf-param"]');
    if(csrf_tag != null) csrf_token = csrf_tag.getAttribute('content');
    if(csrf_param_tag != null) csrf_param = csrf_param_tag.getAttribute('content');
    return (csrf_token != null && csrf_param != null);
  }
  
  void _clickHandler(MouseEvent event) {
    HtmlElement target = event.target; 
    if((event.type == 'click' && target.tagName == "A") || (event.type == 'submit' && target.tagName == "FORM")) {
      if(target.attributes.containsKey('data-confirm')) _triggerConfirm(event, target);
      if(target.attributes.containsKey('data-method') 
          || target.attributes.containsKey('data-remote')) _triggerRemote(event, target);
    }
  }
  
  bool _triggerConfirm(Event event, HtmlElement target) {
    var result = !context.callMethod('confirm', [target.getAttribute('data-confirm')]);
    if(result) { event.preventDefault(); }
    return result;
  }
  
  bool _handleXhrResponse(ProgressEvent event) {
    HttpRequest xhr = event.target;
    var data = xhr.response;
    String responseType = xhr.getResponseHeader('Content-Type');
    if (responseType != null) {
      if(responseType.contains('javascript')) {
        context.callMethod('eval', [data]);
      }
    }    
    return true;
  }
  
  bool _triggerRemote(Event event, HtmlElement target) {
    event.preventDefault();
    FormElement form;
    if(target.tagName == 'FORM') {
      form = target;
    } else {
      form = new FormElement();
      form.method = 'post';
      form.action = target.getAttribute('href');
      form.setAttribute('hidden', 'hidden');
      form.style.display = 'none';
      form.style.visibility = 'hidden';
      document.body.append(form);
    }
    if(form.querySelector('input[name="csrf_param"]') == null) {
      InputElement field = new HiddenInputElement();
      field.name = csrf_param;
      field.value = csrf_token;
      form.append(field);
    }
    
    String method;
    if(target.attributes.containsKey('data-method')) {
      method = target.getAttribute('data-method').toLowerCase();
      var field = new HiddenInputElement();
      field.name = '_method';
      field.value = target.getAttribute('data-method');
      form.append(field);
    }
    else if(target.tagName == 'A') {
      method = 'get';
    }
    else if(target.tagName == 'FORM') {
      method = 'post';
    }
    else {
      throw("Couldn't determine a method!");
    }
    
    String url;
    if(target.tagName == 'A') {
      url = target.getAttribute('href');
    }
    else if(target.tagName == 'FORM') {
      url = target.getAttribute('action');
    }
    else {
      throw("Couldn't determine URL!");
    }

    if (target.attributes.containsKey('data-remote')) {
      var xhr = new HttpRequest();
      xhr.open(method, url, async: true);
      xhr.setRequestHeader('Content-Type', 'x-www-form-urlencoded');
      xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
      xhr.setRequestHeader('Accept', 'text/javascript');
      xhr.onLoadEnd.listen(_handleXhrResponse);
      FormData data = new FormData();
      xhr.send(data);
    }
    else if (target.attributes.containsKey('data-method')) {
      form.submit();
    }
  }
}