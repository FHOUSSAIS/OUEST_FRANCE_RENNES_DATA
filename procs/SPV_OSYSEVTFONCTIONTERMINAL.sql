SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEVTFONCTIONTERMINAL
-- Paramètre d'entrée	: @vp_idTerm : Numéro du terminal où a été effectué la fonction
--			  @vp_msg : Caractère associé à la touche de fonction
-- Paramètre de sortie : Code de retour par défaut
--			  - @CODE_OK: Traitement de la fonction effectué
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ inconnu ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé inconnu ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement de message
-- Descriptif		: Cette procédure traite une fonction opérateur
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

CREATE PROCEDURE [dbo].[SPV_OSYSEVTFONCTIONTERMINAL]
	@vp_idTerm tinyint,
	@vp_msg char (1)
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
declare @v_idTraitement tinyint
declare @v_eval SPVBoolean
declare @v_idTransition int

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_ERREUR tinyint
declare @CODE_KO_INCORRECT tinyint

--définition des constantes
set @CODE_OK = 0
set @CODE_ERREUR = 2
set @CODE_KO_INCORRECT = 11

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK

BEGIN TRAN

-- Récuperation de l'écran courant de l'automate
select @v_idEcran = isNull(OEC_ID, 0) from OSYS_ECRAN, OSYS_ETAT_AUTOMATE, OSYS_AUTOMATE_TERMINAL, OSYS_TERMINAL
where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID and OAT_ETAT_CRT = OEA_ID and OEA_ECRAN = OEC_ID

if (@v_idEcran = 0)
begin
  set @v_codeRetour = @CODE_KO_INCORRECT
end

if (@v_codeRetour = @CODE_OK)
begin
  -- Récuperation du traitement effectué sur la fonction pour cet écran
  select @v_idTraitement = isNull(OFO_TRAITEMENT, 0), @v_eval = isNull(OFO_EVAL, 'N') from OSYS_FONCTION, OSYS_TYPE_FONCTION where OFO_ECRAN = @v_idEcran and OFO_FONCTION = OTF_ID and OTF_CHAR = @vp_msg

  if (@v_idTraitement > 0)
  begin
    -- il y a un traitement à effectuer
    if (@v_eval = 'N')
    begin
      -- le champ OFO_TRAITEMENT contient l'id de la transition à exécuter
      set @v_idTransition = @v_idTraitement
      -- Exécution de la transition
      exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm    
    end
    else begin
      -- le champ OSA_TRAITEMENT contient l'id du traitement permettant d'obtenir la transition à exécuter
      exec @v_idTransition = SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
      if (@v_idTransition > 0)
      begin
        -- Un état suivant a été calculé, on exécute la transaction
        exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm   
      end
      else begin
        set @v_codeRetour = @CODE_ERREUR
      end
    end
  end
end


if @v_codeRetour=@CODE_OK
begin
  COMMIT TRAN
end
else
begin
  ROLLBACK TRAN
end

return @v_codeRetour


