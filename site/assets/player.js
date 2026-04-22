(() => {
  const rows = Array.from(document.querySelectorAll(".case-row"));
  const searchInput = document.getElementById("search-input");
  const modeFilter = document.getElementById("mode-filter");
  const statusFilter = document.getElementById("status-filter");
  const kindFilter = document.getElementById("kind-filter");

  function applyFilters() {
    const query = (searchInput?.value || "").trim().toLowerCase();
    const mode = modeFilter?.value || "all";
    const status = statusFilter?.value || "all";
    const kind = kindFilter?.value || "all";
    for (const row of rows) {
      const matchesQuery = !query || (row.dataset.search || "").toLowerCase().includes(query);
      const matchesMode = mode === "all" || row.dataset.mode === mode;
      const matchesStatus = status === "all" || row.dataset.status === status;
      const matchesKind = kind === "all" || row.dataset.kind === kind;
      row.hidden = !(matchesQuery && matchesMode && matchesStatus && matchesKind);
    }
  }

  searchInput?.addEventListener("input", applyFilters);
  modeFilter?.addEventListener("change", applyFilters);
  statusFilter?.addEventListener("change", applyFilters);
  kindFilter?.addEventListener("change", applyFilters);

  class CastPlayer {
    constructor(root, castHref) {
      this.root = root;
      this.castHref = castHref;
      this.terminal = root.querySelector(".terminal");
      this.playButton = root.querySelector(".js-player-play");
      this.pauseButton = root.querySelector(".js-player-pause");
      this.restartButton = root.querySelector(".js-player-restart");
      this.speedSelect = root.querySelector(".js-player-speed");
      this.scrub = root.querySelector(".js-player-scrub");
      this.events = [];
      this.loaded = false;
      this.playing = false;
      this.timer = null;
      this.index = 0;
      this.startedAt = 0;
      this.offset = 0;

      this.playButton?.addEventListener("click", () => this.run(() => this.play()));
      this.pauseButton?.addEventListener("click", () => this.pause());
      this.restartButton?.addEventListener("click", () => this.run(() => this.restart()));
      this.scrub?.addEventListener("input", () => this.seekFromScrub());
    }

    showError(error) {
      const message = error instanceof Error ? error.message : String(error);
      this.terminal.textContent = `${message}\n`;
    }

    async run(action) {
      try {
        await action();
      } catch (error) {
        this.pause();
        this.showError(error);
      }
    }

    async load() {
      if (this.loaded) return;
      this.terminal.textContent = "Loading cast...\n";
      const response = await fetch(this.castHref);
      if (!response.ok) throw new Error(`Unable to load cast: ${response.status}`);
      const text = await response.text();
      const lines = text.trimEnd().split(/\n/);
      lines.shift();
      this.events = lines.map((line) => JSON.parse(line)).filter((event) => event[1] === "o");
      this.loaded = true;
      this.index = 0;
      this.offset = 0;
      this.terminal.textContent = "";
      this.updateScrub();
    }

    speed() {
      const value = Number(this.speedSelect?.value || 1);
      return Number.isFinite(value) && value > 0 ? value : 1;
    }

    duration() {
      if (!this.events.length) return 0;
      return Number(this.events[this.events.length - 1][0]) || 0;
    }

    updateScrub() {
      if (!this.scrub) return;
      const total = this.duration();
      const position = this.index <= 0 ? 0 : Number(this.events[Math.min(this.index - 1, this.events.length - 1)][0]) || 0;
      this.scrub.value = total <= 0 ? "0" : String(Math.round((position / total) * 1000));
    }

    renderUntil(targetSeconds) {
      this.terminal.textContent = "";
      this.index = 0;
      while (this.index < this.events.length && Number(this.events[this.index][0]) <= targetSeconds) {
        this.terminal.textContent += String(this.events[this.index][2]);
        this.index += 1;
      }
      this.terminal.scrollTop = this.terminal.scrollHeight;
      this.offset = targetSeconds;
      this.updateScrub();
    }

    seekFromScrub() {
      const total = this.duration();
      const value = Number(this.scrub?.value || 0);
      const target = total * (value / 1000);
      const wasPlaying = this.playing;
      this.pause();
      this.renderUntil(target);
      if (wasPlaying) this.play();
    }

    schedule() {
      if (!this.playing) return;
      if (this.index >= this.events.length) {
        this.pause();
        return;
      }
      const nextTime = Number(this.events[this.index][0]) || 0;
      const elapsed = ((performance.now() - this.startedAt) / 1000) * this.speed();
      const delay = Math.max(0, ((nextTime - this.offset - elapsed) / this.speed()) * 1000);
      this.timer = window.setTimeout(() => {
        if (!this.playing) return;
        this.terminal.textContent += String(this.events[this.index][2]);
        this.terminal.scrollTop = this.terminal.scrollHeight;
        this.index += 1;
        this.updateScrub();
        this.schedule();
      }, delay);
    }

    async play() {
      await this.load();
      if (this.playing) return;
      this.playing = true;
      this.startedAt = performance.now();
      this.schedule();
    }

    pause() {
      if (this.timer !== null) window.clearTimeout(this.timer);
      this.timer = null;
      if (this.playing) {
        const elapsed = ((performance.now() - this.startedAt) / 1000) * this.speed();
        this.offset += elapsed;
      }
      this.playing = false;
    }

    async restart() {
      this.pause();
      await this.load();
      this.index = 0;
      this.offset = 0;
      this.terminal.textContent = "";
      this.updateScrub();
      await this.play();
    }
  }

  function playerForRow(row) {
    const playerRoot = row?.querySelector("[data-player]");
    const castHref = row?.dataset.playerCast;
    if (!row || !playerRoot || !castHref) return null;
    if (!playerRoot.castPlayer || playerRoot.castPlayer.castHref !== castHref) {
      playerRoot.castPlayer = new CastPlayer(playerRoot, castHref);
    }
    return playerRoot.castPlayer;
  }

  rows.forEach((row) => playerForRow(row));

  document.querySelectorAll(".js-load-cast").forEach((button) => {
    button.addEventListener("click", async () => {
      const row = button.closest(".case-row");
      const player = playerForRow(row);
      if (!row || !player) return;
      row.open = true;
      await player.run(() => player.restart());
    });
  });
})();
