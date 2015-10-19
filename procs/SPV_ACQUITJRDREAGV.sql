SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure            : SPV_ACQUITJDBORDREAGV
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: L'acquittement du journal de bord s'est exécuté correctement
--			  - @CODE_KO_SQL: Une erreur s'est produite lors de l'acquittement
-- Descriptif		: Cette procédure :
--			  1- Supprime du journal de bord des ordres Agv tous les enregistrements
--			  déjà traités (lus) lors de la derniÞre scrutation
--			  2- Marque (acquitte) tous les enregistrements non lus pour les envoyer
--			  aux abonnés concernés.
-----------------------------------------------------------------------------------------
-- Révisions												
-----------------------------------------------------------------------------------------
-- Date			: 01/11/2004
-- Auteur		: S.Loiseau
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_ACQUITJDBORDREAGV] 
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- dÚclaration de variable
declare @v_codeRetour integer
declare @v_idOrdre integer
declare @v_IdAgv tinyint
declare @v_marque bit
declare @v_object tinyint
declare @v_value varchar(50)


-- dÚclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_KO_SQL tinyint

-- dÚfintion des constantes
set @CODE_OK=0
set @CODE_KO_SQL=13

-- initialisation des variables
set @v_codeRetour=@CODE_OK


BEGIN TRANSACTION

-- parcours de tous les enregistrements du journal de bord
-- marquage (acquittement)de tous les enregistrements non lu
-- suppression de tous les enregistrements déjà marqués (déjà lu lors de la dernière scrutation) 
declare c_DetailJdb CURSOR LOCAL for
select JDO_IdOrdre,JDO_Object,JDO_IdAgv,JDO_Value,JDO_Marque from JDB_ORDRE_AGV
for update

-- ouverture du curseur
open c_DetailJdb

fetch next from  c_DetailJdb INTO @v_idOrdre,@v_object,@v_IdAgv,@v_value,@v_marque
while (@@FETCH_STATUS = 0)
begin

  -- si l'enregistrement est marqué: c'est qu'il a déjà été lu, on peut le supprimer
  if (@v_marque=1)
  begin
    delete from JDB_ORDRE_AGV where current of c_DetailJdb 
    if @@ERROR <>0
    begin
      set @v_codeRetour=@CODE_KO_SQL
      break
    end
  end
  else
  begin
    -- si l'enregistrement n'est pas marqué: il faut l'acquitter : marquage de l'enregistrement
    update JDB_ORDRE_AGV set JDO_Marque=1 
    where current of c_DetailJdb
  end

  fetch next from c_DetailJdb INTO @v_idOrdre,@v_object,@v_IdAgv,@v_value,@v_marque
end



-- fermeture du curseur
close c_DetailJdb
deallocate c_DetailJdb


if @v_codeRetour=@CODE_OK
begin
  COMMIT TRANSACTION
  -- on ne renvoie que les enregistrements qui ont été acquités
  -- si il a eu une erreur lors d'un acquittement, c'est pas grave il sera acquitté plus tard
  select JDO_IdOrdre,JDO_Object,JDO_IdAgv,JDO_Value from JDB_ORDRE_AGV
  where JDO_Marque=1
end
else
begin
  ROLLBACK TRANSACTION
end


return @v_codeRetour





