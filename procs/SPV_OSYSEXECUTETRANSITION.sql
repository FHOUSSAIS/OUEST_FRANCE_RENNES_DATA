SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON






-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEXECUTETRANSITION
-- Paramètre d'entrée	: @vp_idTransition : Id de la transition à exécuter .0 pour la transition d'initialisation
--			  @vp_idTerm : Terminal concerné
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: Transition effectuée correctement
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ incorrect ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé incorrect ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement
-- Descriptif		: Cette procédure effectue une transition d'automate
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 28/06/2005
-- Auteur		: M. Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSEXECUTETRANSITION]
	@vp_idTransition int,
	@vp_idTerm tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer
declare @v_idEcran tinyint
declare @v_idAutomate tinyint
declare @v_typeAutomate tinyint
declare @v_idTraitement tinyint
declare @v_delai int
declare @v_cmd varchar(120)
declare @v_idEtatDep tinyint
declare @v_idEtatArr tinyint
declare @v_idEtatCrt tinyint
declare @v_idEtatInit tinyint


-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_KO_ACTION_INCORRECTE_1 int
declare @CODE_KO_ACTION_INCORRECTE_2 int
declare @CODE_KO_INCORRECT int

--définition des constantes
set @CODE_OK = 0
set @CODE_KO_ACTION_INCORRECTE_1 = 21
set @CODE_KO_ACTION_INCORRECTE_2 = 22
set @CODE_KO_INCORRECT = 11

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK

select @v_idAutomate = isNull(OAT_ID, 0), @v_idEtatCrt = isNull(OAT_ETAT_CRT, 0) from OSYS_TERMINAL, OSYS_AUTOMATE_TERMINAL where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID
if (@vp_idTransition > 0)
begin
  -- Transition en cours de fonctionnement
  select @v_idEtatDep = isNull(OTA_ETAT_DEP, 0), @v_idEtatArr = isNull(OTA_ETAT_ARR, 0) from OSYS_TRANSITION_AUTOMATE where OTA_ID = @vp_idTransition
end
else begin
  -- Transition à l'initialisation
  select @v_idEtatArr = isNull(OAT_ETAT_INIT, 0) from OSYS_AUTOMATE_TERMINAL where OAT_ID = @v_idAutomate
end

-- vérification de la cohérence des états
if ((@v_idEtatDep = @v_idEtatCrt) or (@vp_idTransition = 0))
begin
  -- L'état de départ est correct
  set @v_codeRetour = @CODE_OK
end
else begin
  -- L'état de départ est incorrect
  set @v_codeRetour = @CODE_KO_ACTION_INCORRECTE_1
end

-- Vérification de l'existance de la transition
if (@v_codeRetour = @CODE_OK)
begin
  if ((Exists (select 1 from OSYS_TRANSITION_AUTOMATE where OTA_ID = @vp_idTransition)) or (@vp_idTransition = 0))
  begin
    -- La transition entre les 2 états est paramétrée
    set @v_codeRetour = @CODE_OK
  end
  else begin
    -- Pas de transition paramétrée entre les 2 états
    set @v_codeRetour = @CODE_KO_ACTION_INCORRECTE_1
  end
end

-- Vérification que les états de la transition appartiennet au bon type d'automate
if ((@v_codeRetour = @CODE_OK) and (@vp_idTransition > 0))
begin
  select @v_typeAutomate = isNull(OAT_TYPE, 0) from OSYS_AUTOMATE_TERMINAL where OAT_ID = @v_idAutomate
  if (Exists (select 1 from OSYS_ETAT_AUTOMATE where OEA_ID = @v_idEtatDep and OEA_TYPE_AUTOMATE = @v_typeAutomate))
  begin
    if (Exists (select 1 from OSYS_ETAT_AUTOMATE where OEA_ID = @v_idEtatArr and OEA_TYPE_AUTOMATE = @v_typeAutomate))
    begin
      -- Les états appartiennent au bon type
      set @v_codeRetour = @CODE_OK
    end
    else begin
      -- L'état d'arrivé n'est pas du bon type
      set @v_codeRetour = @CODE_KO_ACTION_INCORRECTE_2
    end 
  end
  else begin
    -- L'état de départ n'est pas du bon type
    set @v_codeRetour = @CODE_KO_ACTION_INCORRECTE_1
  end
end

-- vérification de la cohérence de numéro de terminal
if (@v_codeRetour = @CODE_OK)
begin
  if (Exists (select 1 from OSYS_TERMINAL where OTO_ID = @vp_idTerm))
  begin
    -- Numéro de terminal OK
    set @v_codeRetour = @CODE_OK
  end
  else begin
    -- Numéro de terminal inconnu
    set @v_codeRetour = @CODE_KO_INCORRECT
  end
end

-- Exécution de la transistion

-- 1 : mise à jour des états courant et précédent de l'automate
if (@v_codeRetour = @CODE_OK)
begin
  if (@vp_idTransition > 0)
  begin
    -- Transition en cours de fonctionnement
    update OSYS_AUTOMATE_TERMINAL set OAT_ETAT_CRT = @v_idEtatArr, OAT_ETAT_PREC = @v_idEtatDep where OAT_ID = @v_idAutomate
  end
  else begin
    -- Transition dans le cas d'une initialisation du terminal
    select @v_idEtatInit = OAT_ETAT_INIT from OSYS_AUTOMATE_TERMINAL where OAT_ID = @v_idAutomate
    update OSYS_AUTOMATE_TERMINAL set OAT_ETAT_CRT = @v_idEtatInit, OAT_ETAT_PREC = @v_idEtatInit where OAT_ID = @v_idAutomate
  end
end

-- 2 : exécution du traitement de sortie de l'état de départ
if ((@v_codeRetour = @CODE_OK) and (@vp_idTransition > 0))
begin
  select @v_idTraitement = isNull(OEA_SORTIE, 0) from OSYS_ETAT_AUTOMATE where OEA_ID = @v_idEtatDep
  if (@v_idTraitement > 0)
  begin
    exec SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
  end
end

-- 3 : exécution de la transition
if ((@v_codeRetour = @CODE_OK) and (@vp_idTransition > 0))
begin
  select @v_idTraitement = isNull(OTA_TRAITEMENT, 0) from OSYS_TRANSITION_AUTOMATE where OTA_ID = @vp_idTransition
  if (@v_idTraitement > 0)
  begin
    -- Un traitement a été paramétré, on l'exécute
    exec SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
  end

  -- Affichage de l'écran paramétré pour la transition
  select @v_idEcran = isNull(OTA_ECRAN, 0) from OSYS_TRANSITION_AUTOMATE where OTA_ID = @vp_idTransition
  if (@v_idEcran > 0)
  begin
    -- Interdiction de la saisie opérateur
    exec SPV_OSYSEXECUTEECRAN @vp_idTerm, @v_idEcran
    set @v_cmd = 'NCA'+convert(varchar(1), 1)+convert(varchar(1), 1)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd    
    select @v_delai = OTA_DUREE_ECRAN from OSYS_TRANSITION_AUTOMATE where  OTA_ID = @vp_idTransition
    -- Un écran de transition est affiché pendant une durée donnée
    set @v_cmd = 'WAIT_' + convert(varchar, @v_delai)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm, @v_cmd
  end

end

-- 4 : exécution du traitement d'entrée de l'état d'arrivé
if (@v_codeRetour = @CODE_OK)
begin
  select @v_idTraitement = isNull(OEA_ENTREE, 0) from OSYS_ETAT_AUTOMATE where OEA_ID = @v_idEtatArr
  if (@v_idTraitement > 0)
  begin
    exec SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
  end
end

-- 5 : exécution de l'écran de l'état d'arrivé
if (@v_codeRetour = @CODE_OK)
begin
  select @v_idEcran = OEC_ID from OSYS_ECRAN, OSYS_ETAT_AUTOMATE where OEC_ID = OEA_ECRAN and OEA_ID = @v_idEtatArr
  if (@v_idEcran > 0)
  begin
    exec @v_codeRetour = SPV_OSYSEXECUTEECRAN @vp_idTerm, @v_idEcran
  end
end

-- 6 : si l'état est l'état initial de l'automate, on raz les saisies et la CaB lus
if (@v_codeRetour = @CODE_OK)
begin
  if (Exists (select 1 from OSYS_AUTOMATE_TERMINAL where OAT_ID = @v_idAutomate and OAT_ETAT_INIT = @v_idEtatArr))
  begin
    -- L'état d'arrivé de la transition est l'état initial, on raz le stockage des saisies et des lectures CaB
    update OSYS_SAISIE_VALUE  set OSV_VALUE = NULL where OSV_AUTOMATE = @v_idAutomate
    update OSYS_CAB_VALUE  set OCV_VALUE = NULL where OCV_AUTOMATE = @v_idAutomate
  end
end

return @v_codeRetour



