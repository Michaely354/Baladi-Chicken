export function offersMarkup(offers, escape) {
  return `<section class="daily-offers" id="today-offers" aria-labelledby="offers-title">
    <header class="section-head">
      <div><span class="section-en" lang="en">TODAY’S OFFERS</span><h2 id="offers-title">عروض اليوم</h2></div>
    </header>
    <div class="offer-cards">${offers.length ? offers.map(offer => `
      <article class="offer-card">
        <div><h3 dir="auto">${escape(offer.title)}</h3>${offer.details ? `<p dir="auto">${escape(offer.details)}</p>` : ''}</div>
        ${offer.price ? `<strong dir="auto">${escape(offer.price)}</strong>` : ''}
      </article>`).join('') : '<p class="offers-empty">ما في عروض حالياً.</p>'}</div>
  </section>`;
}

export async function getOffers(db) {
  return db.from('menu_offers').select('id,title,details,price').order('created_at', {ascending: false});
}

export function bindOffers(db, escape, notify) {
  const dashboard = document.querySelector('#manage-offers');
  const dialog = document.querySelector('#offers-dialog');
  if (!db) {
    dashboard.disabled = true;
    return;
  }

  async function refresh() {
    const list = dialog.querySelector('#offer-list');
    list.textContent = 'Loading offers…';
    const {data, error} = await getOffers(db);
    if (error) {
      list.textContent = 'Could not load offers. Close and reopen this panel to try again.';
      return;
    }
    list.innerHTML = data.length ? data.map(offer => `
      <div class="archive-row">
        <span dir="auto">${escape(offer.title)}</span>
        <span class="offer-actions"><button type="button" class="text-link" data-edit="${escape(offer.id)}">Edit</button>
        <button type="button" class="text-link danger" data-remove="${escape(offer.id)}">Remove</button></span>
      </div>`).join('') : '<p class="muted small">No active offers.</p>';
    list.onclick = async event => {
      if (dialog.querySelector('#offer-form').inert) return;
      const edit = event.target.closest('[data-edit]');
      if (edit) {
        fill(data.find(offer => offer.id === edit.dataset.edit));
        dialog.querySelector('#offer-title').focus();
        return;
      }
      const remove = event.target.closest('[data-remove]');
      if (!remove || !confirm('Remove this offer from the live menu?')) return;
      remove.disabled = true;
      const {data: removed, error} = await db.from('menu_offers').delete().eq('id', remove.dataset.remove).select('id').single();
      if (error || !removed) {
        dialog.querySelector('#offer-error').textContent = 'Could not remove the offer. Try again.';
        remove.disabled = false;
        return;
      }
      if (dialog.querySelector('#offer-form').dataset.id === removed.id) fill();
      notify('Offer removed from the menu.');
      await refresh();
    };
  }

  function fill(offer) {
    const form = dialog.querySelector('#offer-form');
    form.dataset.id = offer?.id || '';
    form.elements.title.value = offer?.title || '';
    form.elements.details.value = offer?.details || '';
    form.elements.price.value = offer?.price || '';
    form.querySelector('[type=submit]').textContent = offer ? 'Save offer' : 'Publish offer';
    form.querySelector('#cancel-offer-edit').hidden = !offer;
    dialog.querySelector('#offer-error').textContent = '';
  }

  dashboard.onclick = () => {
    dialog.innerHTML = `<div class="sheet-top"><h2 id="offers-editor-title">Today’s Offers</h2>
      <button type="button" class="close-button" id="close-offers" aria-label="Close offers">×</button></div>
      <form id="offer-form">
        <label class="field"><span>Offer title</span><input name="title" id="offer-title" maxlength="100" dir="auto" required placeholder="e.g. فروج عالفحم"></label>
        <label class="field"><span>Details (optional)</span><input name="details" maxlength="180" dir="auto"></label>
        <label class="field"><span>Price (optional)</span><input name="price" maxlength="30" dir="auto" placeholder="e.g. $10"></label>
        <p id="offer-error" role="alert" class="form-error"></p>
        <button class="button primary full" type="submit">Publish offer</button>
        <button class="text-link" type="button" id="cancel-offer-edit" hidden>Cancel edit</button>
      </form>
      <h3 class="offer-list-heading">Active offers</h3><div id="offer-list"></div>`;
    const form = dialog.querySelector('#offer-form');
    dialog.querySelector('#close-offers').onclick = () => { if (!form.inert) dialog.close(); };
    dialog.oncancel = event => { if (form.inert) event.preventDefault(); };
    form.querySelector('#cancel-offer-edit').onclick = () => fill();
    form.onsubmit = async event => {
      event.preventDefault();
      if (form.inert) return;
      const offer = Object.fromEntries(['title', 'details', 'price'].map(key => [key, form.elements[key].value.trim()]));
      const errorMessage = dialog.querySelector('#offer-error');
      if (!offer.title) {
        errorMessage.textContent = 'Enter an offer title.';
        return;
      }
      form.inert = true;
      const action = form.dataset.id ? db.from('menu_offers').update(offer).eq('id', form.dataset.id) : db.from('menu_offers').insert(offer);
      const {error} = await action.select('id').single();
      form.inert = false;
      if (error) {
        errorMessage.textContent = 'Could not save the offer. Try again.';
        return;
      }
      fill();
      notify('Offer is live on the menu.');
      await refresh();
    };
    dialog.showModal();
    refresh();
  };
}
