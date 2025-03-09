{{flutter_js}}
{{flutter_build_config}}

const throbberDiv = document.createElement('div');
throbberDiv.className = "throbber";
document.body.appendChild(throbberDiv);

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
       entryPointBaseUrl: "/journal/"
    });

    if (document.body.contains(throbberDiv)) {
      document.body.removeChild(throbberDiv);
    }
    await appRunner.runApp();
  },
  config: {
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}}
    }
  },
});
