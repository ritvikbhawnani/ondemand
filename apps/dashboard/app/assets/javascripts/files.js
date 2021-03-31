//TODO: FilesApi https://stackoverflow.com/questions/22734188/javascript-module-pattern-with-anonymous-functions
// for now...
//
function alertError(error_title, error_message){
  Swal.fire(error_title, error_message, 'error');
}

function dataFromJsonResponse(response){
  return new Promise((resolve, reject) => {
    Promise.resolve(response)
    .then(response => response.ok ? Promise.resolve(response) : Promise.reject(new Error(response.statusText)))
    .then(response => response.json())
    .then(data => data.error_message ? Promise.reject(new Error(data.error_message)) : resolve(data))
    .catch((e) => reject(e))
  });
}

function newFile(filename){
  fetch(`${history.state.currentDirectoryUrl}/${encodeURI(filename)}?touch=true`, {method: 'put', headers: { 'X-CSRF-Token': csrf_token }})
  .then(response => dataFromJsonResponse(response))
  // TODO: parse JSON response to get id of file created
  // TODO: should return JSON of the created file (similar to the JSON array returned when getting a list of files...)
  .then(() => reloadTable())
  .catch(e => alertError('Error occurred when attempting to create new file', e.message));
}

function newDirectory(filename){
  fetch(`${history.state.currentDirectoryUrl}/${encodeURI(filename)}?dir=true`, {method: 'put', headers: { 'X-CSRF-Token': csrf_token }})
  .then(response => dataFromJsonResponse(response))
  // TODO: parse JSON response to get id of file created
  // TODO: should return JSON of the created file (similar to the JSON array returned when getting a list of files...)
  .then(() => reloadTable())
  .catch(e => alertError('Error occurred when attempting to create new directory', e.message));
}

function reloadTable(url){
  var request_url = url || history.state.currentDirectoryUrl;

  return fetch(request_url, {headers: {'Accept':'application/json'}})
    .then(response => dataFromJsonResponse(response))
    .then(function(data){
      table.clear();
      table.rows.add(data.files);
      table.draw();

      return Promise.resolve(data);
    })
    .catch((e) => {
      // FIXME: change to modeless feedback
      // this should be an alert above "failed to load table with data from X due to error: ..."
      // or even a smaller message, such as in the status bar but with the alert background color etc.
      Swal.fire(e.message, `Error occurred when attempting to access ${request_url}`, 'error');
      return Promise.reject(e);
    });
}

function goto(url, pushState = true, show_processing_indicator = true){
  //FIXME: https://datatables.net/plug-ins/api/processing()???
  // or use other busy signal...
  //
  // if(show_processing_indicator)
  //   table.processing(true);
  //
  //FIXME: odd thing - with history - if you go forward, then backwards, then forward again
  // you get JSON representation instead of HTML representation

  // FIXME: if url == history.state.currentDirectoryUrl
  // do not pushState regardless!
  if(url == history.state.currentDirectoryUrl)
    pushState = false;

  reloadTable(url)
    .then((data) =>{
      $('#path-breadcrumbs').html(data.breadcrumbs_html);
      if(pushState){
        history.pushState({
          currentDirectory: data.path,
          currentDirectoryUrl: data.url
        }, data.name, data.url);
      }
    })
    .finally(() => {
      // if(show_processing_indicator)
      //   table.processing(false)
    });
}

function loading(title){
  Swal.fire({
    title: title,
    allowOutsideClick: false,
    showConfirmButton: false,
    willOpen: () => { Swal.showLoading()  }
  });
}

function doneLoading(){
  Swal.close();
}
