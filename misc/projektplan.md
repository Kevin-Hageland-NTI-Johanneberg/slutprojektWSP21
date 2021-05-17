# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra).

Jag ska skapa en "Investeringssida" där man som företag kan köpa upp idéer från användare. Det fungerar på så sätt att man skapar ett konto som användare och namnet på sitt företag och får möjligheten att kryssa i en box som ger en möjlighet att själv investera i idéer. Ifall man kryssar i denna boxen måste man dessutom fylla i företagets kapital. När detta är gjort så kan man överblicka andra företags inlägg (med ideéer och uppfinningar). Ifall man är inresserad av att investera kan man gå in på inlägget för att hitta mer information och billagor. Varje inlägg har dessutom ett "offer", exempelvis "investera £1000 för 20% i företaget". Om man vill själv lägga ett annorlunda förslag kan man det också via en knapp. TL;DR Draknästet fast digitalt. 

## 2. Vyer (visa bildskisser på dina sidor).

![Grafiskt](grafiskt.png)

## 3. Databas med ER-diagram (Bild på ER-diagram).

![ER-Diagram](er-diagram.png)

## 4. Arkitektur (Beskriv filer och mappar - vad gör/innehåller de?).

Generell struktur:

db
    databas-fil.db
misc
    bilder
    projectplan
    README.md
    (övriga filer)
views
    public
        css
        js
    slim-map-eller-delsida
        .slim-filer-enligt-REST
app.rb
model.rb

-------

Strukturen kommer att vara uppdelad i fyra olika mappar samt två stycken ruby filer. Mapparna består av 'db', 'misc', 'public' samt 'views'. Db kommer att innehålla databaserna för projektet medan public kommer att innehålla det visuella för sidan i form utav css och java script. Public mappen kommer därefter att baseras på innehållet i views där varje mapp är uppbyggda på restful routes med slim-filer. Därefter har vi de två ruby-filerna. App.rb är självaste hjärnan i projektet och innehåller alla routes, sessions, authorizations samt felhantering. Däremot för att koden inte ska bli allt för lång och skriver ut samma funktioner samma gånger, använder vi oss utav model.rb som innehåller en massa hjälpfunktioner som styr bland annat databasinteraktioner, valideringar och authentication. Dessa funktioner använder sedan app.rb för att bygga upp webapplikationen.