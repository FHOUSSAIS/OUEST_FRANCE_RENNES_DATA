SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSAJOUTECOMMANDE
-- Paramètre d'entrée	: @vp_idTerm : Numéro du terminal auquel envoyer la commande
--			  @vp_cmd : Commande à envoyer au terminal	
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: La commande sera envoyée au terminal
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
-- Descriptif		: Cette procédure ajoute dans OSYS_COMMANDE une nouvelle commande à envoyer à un terminal
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

CREATE PROCEDURE [dbo].[SPV_OSYSAJOUTECOMMANDE]
	@vp_idTerm tinyint,
	@vp_cmd varchar(120)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_KO tinyint
declare @CODE_KO_INCONNU tinyint
declare @CODE_KO_INTERDIT tinyint

--définition des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_INCONNU = 7
set @CODE_KO_INTERDIT = 18

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK

-- Test si le numéro de terminal est cohérent
if Exists(select 1 from OSYS_TERMINAL where OTO_ID = @vp_idTerm)
begin
  if (@vp_cmd<>'')
  begin
      -- Ajout de la commande dans la table OSYS_COMMANDE
      insert into OSYS_COMMANDE (OCO_TERM, OCO_MESSAGE, OCO_DATE) values (@vp_idTerm, @vp_cmd, GETDATE())
      if (@@ROWCOUNT=0)
      begin
        -- Erreur d'ajout de la commande
        set @v_codeRetour=@CODE_KO
      end
      else begin
        -- La commande a bien été ajoutée dans la table
        set @v_codeRetour=@CODE_OK
      end
  end  
  else begin
    -- Envoi de chaine vide interdit
    set @v_codeRetour=@CODE_KO_INTERDIT
  end
end
else begin
  -- Le terminal n'existe pas
  set @v_codeRetour=@CODE_KO_INCONNU
end

return @v_codeRetour




